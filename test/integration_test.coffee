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
      var __hasProp = Object.prototype.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

      this.Widget = (function(_super) {

        __extends(Widget, _super);

        function Widget() {
          Widget.__super__.constructor.apply(this, arguments);
        }

        Widget.prototype.initialize = function() {
          return console.log("initializing widget ...");
        };

        return Widget;

      })(Backbone.View);

    }).call(this);

    (function() {

      $(function() {
        return new Widget;
      });

    }).call(this);

    """
    done()
