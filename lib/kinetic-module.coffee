http = require 'http'
querystring = require 'querystring'

module.exports =
class KineticModule

  MAX_ATTEMPTS: 5
  method: 'POST'
  encoding: 'utf8'
  contents: ''
  file_name: ''
  file_extension: ''

  constructor: (host, path, opts) ->
    @host = host
    @path = path
    @opts = opts

    atom.menu.add [
      {
        'label': 'Packages'
        'submenu': [
          'label': 'Kinetic'
          'submenu': [
            {
              'label': "Upload to #{this.constructor.name}",
              'command': "kinetic:upload-to-#{this.constructor.name}"
            }
          ]
        ]
      }
    ]

  getFileContents: ->
    atom.workspace.getActiveEditor().buffer.cachedText

  getFileName: ->
    atom.workspaceView.find('.tab-bar .tab.active > div[data-name]').attr('data-name')

  getFileExtension: ->
    fl = @getFileName().split('.')
    fl[fl.length - 1]

  before_upload: ->
    @opts[@contents]       = @getFileContents()
    @opts[@file_name]      = @getFileName()
    @opts[@file_extension] = @getFileExtension()

  upload: (attempt) ->
    @before_upload() unless (@opts[@contents] && @opts[@file_name] && @opts[@file_extension])

    attempt = if attempt then (attempt + 1) else 1

    # send the request.. resp will be set.
    @request((resp) =>
      if !@check(resp)
        @done(resp)
      else if attempt < @MAX_ATTEMPTS
        return @upload(attempt)
      else
        atom.confirm(
          message: "@check() did not return correctly after #{@MAX_ATTEMPTS} tries.",
          detailedMessage: "Please report this error to http://github.com/ddavison/kinetic/issues " +
                           "with the following information:\n\n\t" +
                           "file_name: #{@file_name}\n\t" +
                           "opts: #{JSON.stringify(@opts)}\n\n" +
                           "Response: #{resp}"
        )
        return

      @after_upload(resp)
    )

  request: (callback) ->
    data = querystring.stringify(@opts)

    options =
      host: @host,
      port: 80,
      path: @path,
      method: @method,
      headers:
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': data.length

    req = http.request options, (response) =>
      response.setEncoding(@encoding)
      response.on('data',
        (chunk) =>
          callback(chunk)
      )

    req.write(data)
    req.end()

  done: (resp) ->
    atom.clipboard.write(resp)
    atom.confirm(
      message: "Your code has been uploaded to #{this.constructor.name}",
      detailedMessage: "\n\t#{resp}\n\n\n this has been copied to your clipboard."
    )

  after_upload: (resp) ->
    # do nothing, unless overridden.

  ###
  Middleware function to make sure that the upload is fine.  If not, make adjustments
  ###
  check: (resp) ->
    atom.confirm(
      message: 'There was no response...',
      detailedMessage: "There was no response from:\n===\n#{@host + ' ' + @path}"
    ) if resp == ''
    false
