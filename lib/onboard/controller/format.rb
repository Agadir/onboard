require 'sinatra/base'

require 'onboard/extensions/sinatra/base'
require 'onboard/extensions/sinatra/templates'

class OnBoard
  class Controller < ::Sinatra::Base

    @@formats = %w{html json} # order matters
    @@formats << 'rb' if development?

  end
end

