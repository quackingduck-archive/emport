#@export ErrorWidget
#@import Backbone

class @Widget extends Backbone.View

  initialize: ->
    # inconsistent indentation should throw a compile error
    console.log "initializing widget ...",
      "with inconsistent indentation"

