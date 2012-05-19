
/*

Example usage:

    emport 'app.coffee', path: 'frontend', map:
      'vendor/jquery.js'      : exports: '$'
    , (err, js) ->
      throw err if err?
      console.log js

The value of the `js` variable in the callback will be the compiled js for
`app.coffee` plus all its dependecies (and its dependecies dependecies and so
on).

Here's a rough overview of what happens when `emport` is called:

* The base path is scanned (infinitely deep) for .js and .coffee files
* All of those files are read into memory, in parallel
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

n.b. The base path is either the value of options.path or the directory that
targetFilename is in.
*/

(function() {
  var async, coffee, emport, expandMapShorthand, fs, glob, parseLine, parseSourceForImportsAndExports, path, resolveDeps,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  path = require('path');

  fs = require('fs');

  glob = require('glob');

  async = require('async');

  coffee = require('coffee-script');

  module.exports = emport = function(targetFilename, options, callback) {
    var basePaths, emportMap;
    basePaths = options.paths || [path.dirname(targetFilename)];
    emportMap = {};
    return async.forEachSeries(basePaths, function(basePath, cb) {
      return async.waterfall([
        function(cb) {
          return glob("" + basePath + "/**/*.@(js|coffee)", cb);
        }, function(filenames, cb) {
          return async.forEach(filenames, function(filename, eachCb) {
            return fs.readFile(filename, 'utf8', function(err, contents) {
              var importsAndExports, relPath;
              if (contents == null) return eachCb();
              relPath = path.relative(basePath, filename);
              importsAndExports = parseSourceForImportsAndExports(contents);
              emportMap[relPath] = importsAndExports;
              emportMap[relPath].contents = contents;
              return eachCb();
            });
          }, cb);
        }
      ], cb);
    }, function(err) {
      var contents, contentsInOrder, dependencies, exportVar, exports, filename, filenamesInOrder, importVar, importsAndExports, _i, _len, _ref, _ref2;
      if (err != null) return callback(err);
      if (options.map != null) {
        expandMapShorthand(options.map);
        _ref = options.map;
        for (filename in _ref) {
          importsAndExports = _ref[filename];
          if (emportMap[filename] == null) {
            return callback("" + filename + " not found");
          }
          emportMap[filename].imports = importsAndExports.imports;
          emportMap[filename].exports = importsAndExports.exports;
        }
      }
      exports = {};
      for (filename in emportMap) {
        importsAndExports = emportMap[filename];
        _ref2 = importsAndExports.exports;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          exportVar = _ref2[_i];
          exports[exportVar] = filename;
        }
      }
      dependencies = {};
      for (filename in emportMap) {
        importsAndExports = emportMap[filename];
        dependencies[filename] = (function() {
          var _j, _len2, _ref3, _results;
          _ref3 = importsAndExports.imports;
          _results = [];
          for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
            importVar = _ref3[_j];
            _results.push(exports[importVar]);
          }
          return _results;
        })();
      }
      filenamesInOrder = resolveDeps(targetFilename, dependencies);
      filenamesInOrder.push(targetFilename);
      contentsInOrder = (function() {
        var _j, _len2, _results;
        _results = [];
        for (_j = 0, _len2 = filenamesInOrder.length; _j < _len2; _j++) {
          filename = filenamesInOrder[_j];
          contents = emportMap[filename].contents;
          if (filename.match(/\.coffee$/)) {
            _results.push(coffee.compile(contents));
          } else {
            _results.push(contents);
          }
        }
        return _results;
      })();
      return callback(null, contentsInOrder.join("\n"));
    });
  };

  resolveDeps = function(filename, depsMap, resolvedDeps) {
    var depFilename, depFilenames, _i, _len;
    if (resolvedDeps == null) resolvedDeps = [];
    if (!(depFilenames = depsMap[filename])) return [];
    for (_i = 0, _len = depFilenames.length; _i < _len; _i++) {
      depFilename = depFilenames[_i];
      if (!(__indexOf.call(resolvedDeps, depFilename) < 0)) continue;
      resolveDeps(depFilename, depsMap, resolvedDeps);
      resolvedDeps.push(depFilename);
    }
    return resolvedDeps;
  };

  parseSourceForImportsAndExports = function(source) {
    var line, out, _i, _len, _ref;
    out = {
      imports: [],
      exports: []
    };
    _ref = source.split("\n");
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      line = _ref[_i];
      parseLine(line, out);
    }
    return out;
  };

  parseLine = function(line, out) {
    var match;
    match = line.match(/^(?:#|\/\/)@((?:im|ex)port)\s+(\S+)/);
    if (match != null) return out[match[1] + 's'].push(match[2]);
  };

  expandMapShorthand = function(inputMap) {
    var filename, h, k, _results;
    _results = [];
    for (filename in inputMap) {
      h = inputMap[filename];
      _results.push((function() {
        var _i, _len, _ref, _results2;
        _ref = ['imports', 'exports'];
        _results2 = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          if (h[k] == null) h[k] = [];
          if (typeof h[k] === 'string') {
            _results2.push(h[k] = [h[k]]);
          } else {
            _results2.push(void 0);
          }
        }
        return _results2;
      })());
    }
    return _results;
  };

}).call(this);
