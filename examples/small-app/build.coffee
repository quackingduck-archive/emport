emport = require '../../src/emport'

emport 'app.coffee', paths: [ 'frontend' ], map:
  'vendor/jquery.js'      : exports: '$'
  'vendor/underscore.js'  : exports: '_'
  'vendor/backbone.js'    : exports: 'Backbone', imports: ['_', '$']
, (err, js) ->
  throw err if err?
  console.log js
