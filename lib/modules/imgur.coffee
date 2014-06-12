KineticModule = require '../kinetic-module'

module.exports =
class Imgur extends KineticModule
  constructor: ->
    super('https://api.imgur.com/3/image', 'image',
      type: 'base64',
      description: 'Upload from atom kinetic package.'
    )

  before_upload: ->
    @opts['title'] = @getFileName()
    @headers['Authorization'] = 'Client-ID b8107721a0a72ef'

  after_upload: (resp) ->
    JSON.parse(resp).data.link
