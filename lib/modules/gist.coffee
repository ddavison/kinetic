KineticModule = require '../kinetic-module'

module.exports =
class Gist extends KineticModule

  constructor: ->
    super('https://api.github.com/gists', 'json'
      description: 'Gist created from kinetic',
      public: false,
      files: {}
    )

  before_upload: ->
    @opts['files'][@getFileName()] = {}
    @opts['files'][@getFileName()]['content'] = @getFileContents()

  after_upload: (resp) ->
    resp['html_url']
