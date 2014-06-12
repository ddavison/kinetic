KineticModule = require '../kinetic-module'

module.exports =
class HasteBin extends KineticModule
  constructor: ->
    super('http://hastebin.com/documents', 'text')

  after_upload: (resp) ->
    'http://hastebin.com/' + JSON.parse(resp).key
