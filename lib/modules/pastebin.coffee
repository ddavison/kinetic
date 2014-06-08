KineticModule = require '../kinetic-module'

module.exports =
class PasteBin extends KineticModule
  dev_keys: [
    '7fabc5b4eb973635b54eae7875443673',
    '3278f5471c12f6d4997c35c5a2aa075f',
    '68f1b226407971cac56b8506239f38e9'
  ]
  contents:       'api_paste_code'
  file_name:      'api_paste_name'
  file_extension: 'api_paste_format'

  constructor: ->
    super('pastebin.com', '/api/api_post.php',
      api_option: 'paste',
      api_dev_key: @getRandomDevKey() # there is a limit on pastes :(
      api_paste_private: '1' # 0=public,1=unlisted,2=private
      api_paste_expire_date: '10M',
    )

  check: (resp) ->
    # default to text if the paste format is wrong.
    if resp.indexOf @file_extension
      @opts[@file_extension] = ''
      return true

    if resp.indexOf 'Post limit'
      @opts['api_dev_key'] = @getRandomDevKey()
      return true

  getRandomDevKey: ->
    @dev_keys[Math.floor(Math.random() * @dev_keys.length)]
