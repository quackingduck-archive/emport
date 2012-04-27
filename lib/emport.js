(function() {
  var async, coffee, emport, expandMapShorthand, fs, glob, parseLine, parseSourceForImportsAndExports, path, resolveDeps,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  path = require('path');

  fs = require('fs');

  glob = require('glob');

  async = require('async');

  coffee = require('coffee-script');

  module.exports = emport = function(filename, options, callback) {
    var basePath, dependencies, exportVar, exports, extendedMap, f, importVar, importsAndExports, _i, _len, _ref, _ref2;
    extendedMap = (_ref = options.map) != null ? _ref : {};
    expandMapShorthand(extendedMap);
    exports = {};
    for (f in extendedMap) {
      importsAndExports = extendedMap[f];
      _ref2 = importsAndExports.exports;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        exportVar = _ref2[_i];
        exports[exportVar] = f;
      }
    }
    dependencies = {};
    for (f in extendedMap) {
      importsAndExports = extendedMap[f];
      dependencies[f] = (function() {
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
    basePath = options.path || __dirname;
    return glob("" + basePath + "/**/*.*", function(err, filenames) {
      var f;
      if (err != null) callback(err);
      filenames = (function() {
        var _j, _len2, _results;
        _results = [];
        for (_j = 0, _len2 = filenames.length; _j < _len2; _j++) {
          f = filenames[_j];
          if (f.match(/\.(js|coffee)$/)) _results.push(f);
        }
        return _results;
      })();
      return async.map(filenames, fs.readFile, function(err, fileContents) {
        var c, content, contents, contentsInOrder, exportVar, f, filenamesInOrder, i, importVar, importsAndExport, _j, _len2, _len3, _len4, _len5, _ref3;
        importsAndExports = (function() {
          var _j, _len2, _results;
          _results = [];
          for (_j = 0, _len2 = fileContents.length; _j < _len2; _j++) {
            content = fileContents[_j];
            _results.push(parseSourceForImportsAndExports(content.toString('utf8')));
          }
          return _results;
        })();
        for (i = 0, _len2 = importsAndExports.length; i < _len2; i++) {
          importsAndExport = importsAndExports[i];
          _ref3 = importsAndExport.exports;
          for (_j = 0, _len3 = _ref3.length; _j < _len3; _j++) {
            exportVar = _ref3[_j];
            exports[exportVar] = path.relative(basePath, filenames[i]);
          }
        }
        for (i = 0, _len4 = importsAndExports.length; i < _len4; i++) {
          importsAndExport = importsAndExports[i];
          f = path.relative(basePath, filenames[i]);
          if (dependencies[f] == null) dependencies[f] = [];
          dependencies[f] = dependencies[f].concat((function() {
            var _k, _len5, _ref4, _results;
            _ref4 = importsAndExport.imports;
            _results = [];
            for (_k = 0, _len5 = _ref4.length; _k < _len5; _k++) {
              importVar = _ref4[_k];
              _results.push(exports[importVar]);
            }
            return _results;
          })());
        }
        filenamesInOrder = resolveDeps(filename, dependencies);
        filenamesInOrder.push(filename);
        contents = {};
        for (i = 0, _len5 = filenames.length; i < _len5; i++) {
          f = filenames[i];
          contents[path.relative(basePath, f)] = fileContents[i].toString('utf8');
        }
        contentsInOrder = (function() {
          var _k, _len6, _results;
          _results = [];
          for (_k = 0, _len6 = filenamesInOrder.length; _k < _len6; _k++) {
            f = filenamesInOrder[_k];
            c = contents[f];
            if (f.match(/\.coffee$/)) c = coffee.compile(c);
            _results.push(c);
          }
          return _results;
        })();
        return callback(null, contentsInOrder.join("\n"));
      });
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

}).call(this);
