req = require 'request'
querystring = require 'querystring'

module.exports =
class KineticModule

  MAX_ATTEMPTS: 5
  contents: ''
  file_name: ''
  file_extension: ''
  requestError: false
  api_type: 'json' # default to json

  ###
    @param url the url of the service
    @param api_type json || form || body
    @param opts the api options to use
  ###
  constructor: (url, api_type, opts) ->
    @opts = opts
    @api_type = api_type
    @request_opts =
      'url': url,
      headers:
        'User-Agent': 'atom-kinetic'

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

    atom.workspaceView.command "kinetic:upload-to-#{@constructor.name}", =>
      @upload()

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
    try
      @before_upload()

      attempt = if attempt then (attempt + 1) else 1

      # send the request..
      @request((resp) =>
        if !@check(resp)
          @done(@after_upload(resp))
        else if attempt < @MAX_ATTEMPTS
          return @upload(attempt)
        else
          return atom.confirm(
            message: "@check() did not return correctly after #{@MAX_ATTEMPTS} tries.",
            detailedMessage: "Please report this error to http://github.com/ddavison/kinetic/issues " +
                             "with the following information:\n\n\t" +
                             "file_name: #{@file_name}\n\t" +
                             "opts: #{JSON.stringify(@opts)}\n\n" +
                             "Response: #{resp}\n\n" +
                             "Request Headers: \n#{JSON.stringify(@request_opts)}"
          ) if !@requestError # if there was a request error, just ignore it.
          return
      )
    catch err
      atom.confirm(
        message: 'There was an error!'
        detailedMessage: 'If you are feeling collaborative, itd help a lot if you posted the below information to ' +
                         'http://github.com/ddavison/kinetic/issues\n\n' +
                         "\tError: #{err}"
      )

  request: (callback) ->
    switch @api_type
      when 'json'
        @request_opts.json = @opts
      when 'form'
        @request_opts.form = @opts
      else
        @request_opts.body = querystring.stringify(@opts)

    req.post(@request_opts, (error, response, body) =>
      if !error and (response.statusCode == 200 || response.statusCode == 201)
        callback(body)
      else
        atom.confirm(
          message: 'There was an error with the request.',
          detailedMessage: "The server responded with:\n" +
                           "\tstatusCode: #{response.statusCode}\n" +
                           "\terror: #{error}\n" +
                           "\tbody: #{body}\n"
        )
        @requestError = true
    )

  done: (final_url)->
    atom.clipboard.write(final_url)
    atom.confirm(
      message: "Your code has been uploaded to #{this.constructor.name}",
      detailedMessage: "\n\t#{final_url}\n\n\n this has been copied to your clipboard."
    )

  ###
  # What to execute before @done() is called.
  # Change this if you need to modify the returned data somehow.
  ###
  after_upload: (resp) ->
    resp

  ###
  Middleware function to make sure that the upload is fine.  If not, make adjustments
  ###
  check: (resp) ->
    console.log 'checking.. response: ' + resp
    atom.confirm(
      message: 'There was no response...',
      detailedMessage: "There was no response from:\n===\n#{@host + ' ' + @path}"
    ) if resp == ''
    return false
