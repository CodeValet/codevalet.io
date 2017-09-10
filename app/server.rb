require 'haml'
require 'raven'
require 'sinatra/base'

module CodeValet
  # Root API server for this service
  class Server < Sinatra::Base
    enable  :sessions
    enable  :raise_errors
    disable :show_exceptions

    set :public_folder, File.dirname(__FILE__) + '/../assets'
    set :views, File.dirname(__FILE__) + '/../views'

    get '/' do
      haml :index
    end
  end
end
