# Not implemented and/or supported in this release


require 'fileutils'

class OnBoard
  module Service
    module RADIUS
      ROOTDIR = File.dirname(__FILE__)
      CONFDIR = File.join ROOTDIR, '/etc/config'
      $LOAD_PATH.unshift  ROOTDIR + '/lib'
      if OnBoard.web?
        OnBoard.find_n_load ROOTDIR + '/etc/menu'
        OnBoard.find_n_load ROOTDIR + '/controller'
      end
    end
  end
end

