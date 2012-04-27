assert = require 'assert'
emport = require '../src/emport'

test "example/small-app", (done) ->
  emport 'app.coffee', path: __dirname+'/../examples/small-app/frontend', map:
    'vendor/jquery.js'      : exports: '$'
    'vendor/underscore.js'  : exports: '_'
    'vendor/backbone.js'    : exports: 'Backbone', imports: '_'
  , (err, js) ->
    throw err if err?
    assert.equal js, """
    // jquery

    // underscore

    // backbone

    (function() {

      this.Widget = {};

    }).call(this);

    (function() {

      $(function() {
        return console.log("hello world");
      });

    }).call(this);

    """
    done()
