fs = require 'fs'

module.exports =
  modulesPath: atom.packages.packageDirPaths[0] + '/kinetic/lib/modules'
  configDefaults:
    copyToClipboard: true

  activate: ->
    files = fs.readdirSync @modulesPath

    for file in files
      KineticModule = require './modules/' + file.split('.')[0]
      m = new KineticModule()
