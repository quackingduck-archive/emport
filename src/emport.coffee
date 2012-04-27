path = require 'path'
fs = require 'fs'
glob = require 'glob'
async = require 'async'
coffee = require 'coffee-script'

# I was really ill when I wrote this. The code is terrible. Most of the names
# for things are wrong. Implementation could use a rewrite. The api is fine
# though.

# Right now the behavior for defining imports/exports in for the same file in
# both the file contents and the map passed into options is undefined. The
# options one should probably extend the one computed from the file contents.

# No errors are thrown when attempting to import a variable that was never
# exported

module.exports = emport = (filename, options, callback) ->

  extendedMap = options.map ? {}
  expandMapShorthand extendedMap

  # A map of declared globals to filenames
  exports = {}

  for f, importsAndExports of extendedMap
    for exportVar in importsAndExports.exports
      exports[exportVar] = f

  # A map of filenames to immediate dependencies
  dependencies = {}
  for f, importsAndExports of extendedMap
    dependencies[f] = (exports[importVar] for importVar in importsAndExports.imports)

  basePath = options.path or __dirname

  glob "#{basePath}/**/*.*", (err, filenames) ->
    callback(err) if err?
    # filter out non-js or coffee
    filenames = (f for f in filenames when f.match /\.(js|coffee)$/)
    # parallel read everything
    async.map filenames, fs.readFile, (err, fileContents) ->

      # Parse out import and export metadata from each file
      importsAndExports = (parseSourceForImportsAndExports content.toString('utf8') for content in fileContents)

      # Update exports map
      for importsAndExport, i in importsAndExports
        # console.log "dadsa", importsAndExport
        for exportVar in importsAndExport.exports
          exports[exportVar] = path.relative basePath, filenames[i]

      # Then update dependencies map
      for importsAndExport, i in importsAndExports
        f = path.relative basePath, filenames[i]
        dependencies[f] ?= []
        dependencies[f] = dependencies[f].concat (exports[importVar] for importVar in importsAndExport.imports)

      filenamesInOrder = resolveDeps filename, dependencies
      filenamesInOrder.push filename

      # A map of filenames to their contents
      contents = {}
      contents[path.relative(basePath, f)] = fileContents[i].toString('utf8') for f, i in filenames

      contentsInOrder = for f in filenamesInOrder
        c = contents[f]
        c = coffee.compile c if f.match /\.coffee$/
        c

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

expandMapShorthand = (inputMap) ->
  for filename, h of inputMap
    for k in ['imports', 'exports']
      h[k] ?= []
      h[k] = [h[k]] if typeof h[k] is 'string'

parseSourceForImportsAndExports = (source) ->
  out = { imports: [], exports: [] }
  parseLine line, out for line in source.split "\n"
  out

parseLine = (line, out) ->
  match = line.match /^(?:#|\/\/)@((?:im|ex)port)\s+(\S+)/
  out[match[1]+'s'].push match[2] if match?
