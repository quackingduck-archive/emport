###

Example usage:

    emport 'app.coffee', paths: [ 'frontend' ], map:
      'vendor/jquery.js'      : exports: '$'
    , (err, js) ->
      throw err if err?
      console.log js

The value of the `js` variable in the callback will be the compiled js for
`app.coffee` plus all its dependecies (and its dependecies dependecies and so
on).

Here's a rough overview of what happens when `emport` is called:

* If no base paths are provided - via the `paths` argument - the directory of
  the target file is used.
* The base paths are scanned for all files matching the optional glob or
  against the default glob pattern - all js and coffee files,
  infinitely deep
* All of the matched files are read into memory, in parallel
* Each file is scanned for the special import and export comments
* An `emportMap` data strcuture is built up containing:
  * The file name (relative to the base path)
  * The file's contents
  * What variables it exports
  * What variables it imports
* If the `map` arg option was given, it's value is sanitized and merged with
  the `emportMap`. Entries in the `map` arg override existing entries in
  `emportMap`
* An `exports` data structure is built up containing entries like:
    "$": "vendor/jquery.js"
* A `dependencies` data structure is built up containing entries like:
    "backbone.js": [ "underscore.js" ]
  the key is the filename and the value is it's immediate dependencies
* The `targetFilename` is then has its dependencies recursively resolved using
  the above data structure. I kinda freestyled the algorithm to do this
  (the body of `resolveDeps`) ... it might have buggy edge cases I've
  overlooked.
* Now that we have an array of dependencies (with no dupes) we appened the
  `targetFilename` to that and then grab the contents for each filename and
  concatenate them together. If the filename has a `.coffee` extension then
  its compiled first.
* Finally the callback is called with that string as the second arg.

###

path   = require 'path'
fs     = require 'fs'
glob   = require 'glob'
async  = require 'async'
coffee = require 'coffee-script-redux'

module.exports = emport = (targetFilename, options, callback) ->
  basePaths = options.paths or [path.dirname(targetFilename)]

  # data structure with entries like
  #   'filename': imports: [], exports: [], contents: "... file contents ..."
  emportMap = {}

  async.forEachSeries basePaths, ((basePath, cb) ->
    async.waterfall [

      # enumerate all paths
      (cb) ->
        [basePath, basePathGlob] = basePath.split ' '
        basePathGlob ?= '**/*.@(js|coffee)'
        glob basePath+'/'+basePathGlob, cb

      (filenames, cb) ->
        # parrallel process each file
        async.forEach filenames, ((filename, eachCb) ->
          fs.readFile filename, 'utf8', (err, contents) ->
            return eachCb() unless contents? # ignores directories

            relPath = path.relative basePath, filename
            importsAndExports = parseSourceForImportsAndExports contents
            emportMap[relPath] = importsAndExports
            emportMap[relPath].contents = contents

            eachCb()
        ), cb

    ], cb
  ), (err) ->
    return callback(err) if err?

    # apply the map given in options over map produced from scanning files
    if options.map?
      expandMapShorthand options.map
      for filename, importsAndExports of options.map
        return callback("#{filename} not found") unless emportMap[filename]?
        emportMap[filename].imports = importsAndExports.imports
        emportMap[filename].exports = importsAndExports.exports

    # A map of export variables to file names
    exports = {}
    for filename, importsAndExports of emportMap
      for exportVar in importsAndExports.exports
        exports[exportVar] = filename

    # A map of filenames to immediate dependencies
    dependencies = {}
    for filename, importsAndExports of emportMap
      dependencies[filename] =
        for importVar in importsAndExports.imports
          exports[importVar] ? (throw new Error "no file exports #{importVar}, called from #{filename}")

    filenamesInOrder = resolveDeps targetFilename, dependencies
    filenamesInOrder.push targetFilename

    try
      contentsInOrder = getContentsInOrder filenamesInOrder, emportMap
    catch e
      return callback e
    callback null, contentsInOrder.join "\n"


# Takes a filename and a map of filenames to dependencies. Returns an array of
# of filenames such that is all the dependencies for the filename are included
# in the right order.
resolveDeps = (filename, depsMap, resolvedDeps = []) ->
  return [] unless depFilenames = depsMap[filename]
  for depFilename in depFilenames when depFilename not in resolvedDeps
    resolveDeps depFilename, depsMap, resolvedDeps
    resolvedDeps.push depFilename
  resolvedDeps

parseSourceForImportsAndExports = (source) ->
  out = { imports: [], exports: [] }
  parseLine line, out for line in source.split "\n"
  out

# mutates `out`
parseLine = (line, out) ->
  match = line.match /^(?:#|\/\/)@((?:im|ex)port)\s+(\S+)/
  out[match[1]+'s'].push match[2] if match?

# mutates `inputMap`
expandMapShorthand = (inputMap) ->
  for filename, h of inputMap
    for k in ['imports', 'exports']
      h[k] ?= []
      h[k] = [h[k]] if typeof h[k] is 'string'


getContentsInOrder = (filenamesInOrder, emportMap) ->
  for filename in filenamesInOrder
    contents = emportMap[filename].contents
    if filename.match /\.coffee$/
      try
        coffee.cs2js contents, filename: filename
      catch e
        e.message += "\n when processing #{filename}"
        throw e
    else
      contents

