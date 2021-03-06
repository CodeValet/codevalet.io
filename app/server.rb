#!/usr/bin/env ruby

require 'haml'
require 'sinatra/base'
require 'warden/github'
require 'yaml'

Haml::TempleEngine.disable_option_validator!

module CodeValet
  # Simple class for rendering an authentication failure
  class AuthFailure < Sinatra::Base
    get '/unauthenticated' do
      status 403
      <<-EOS
      <h2>Unable to authenticate, sorry bud.</h2>
      <p>#{env['warden'].message}</p>
      <p>#{ENV['REDIRECT_URI']}</p>
      <p>#{ENV['GITHUB_CLIENT_ID']}</p>
      EOS
    end
  end

  # Basic webapp for serving some basic pages on codevalet.io
  class App < Sinatra::Base
    include Warden::GitHub::SSO

    enable  :sessions
    enable  :raise_errors
    disable :show_exceptions

    set :public_folder, File.dirname(__FILE__) + '/assets'

    use Warden::Manager do |config|
      config.failure_app = AuthFailure
      config.default_strategies :github
      config.scope_defaults :default, :config => {
        :scope            => 'read:public_repo,user:email',
        :client_id        => ENV['GITHUB_CLIENT_ID'] || 'a6f2001b9e6c3fabf85c',
        :client_secret    => (ENV['GITHUB_CLIENT_SECRET'] || \
                              '0672e14addb9f41dec11b5da1219017edfc82a58').chomp,
        :redirect_uri     => ENV['REDIRECT_URI'] || 'http://localhost:9292/github/authenticate',
      }

      config.serialize_from_session do |key|
        Warden::GitHub::Verifier.load(key)
      end

      config.serialize_into_session do |user|
        Warden::GitHub::Verifier.dump(user)
      end
    end

    helpers do
      def production?
        ENV['PRODUCTION']
      end

      def masters
        file_path = File.expand_path(File.dirname(__FILE__) + '/monkeys.txt')
        @monkeys ||= File.open(file_path, 'r').readlines.map(&:chomp).sort
      end

      def admin?
        return false unless env['warden'].user
        return env['warden'].user.login == 'rtyler'
      end
    end

    get '/' do
      haml :index,
           :layout => :_base,
           :locals => {
             :monkeys => masters,
           }
    end

    get '/doc' do
      haml :doc, :layout => :_base
    end

    get '/profile' do
      if env['warden'].user
        haml :profile, :layout => :_base,
                       :locals => {
                         :user => env['warden'].user,
                         :monkeys => masters,
                         :admin => admin?,
                       }
      else
        redirect to('/')
      end
    end

    get '/login' do
      env['warden'].authenticate!
      redirect to('/profile')
    end

    get '/github/authenticate' do
      puts request.inspect
      env['warden'].authenticate!

      redirect_path = [
        'securityRealm/finishLogin?from=%2Fblue&',
        env['QUERY_STRING'],
      ].join('')

      if session[:jenkins] && env['warden'].user
        session[:jenkins] = nil
        href = "http://localhost:8080/#{redirect_path}"
        login = env['warden'].user.login

        if production?
          if session[:admin_instance]
            login = session[:admin_instance]
            session[:admin_instance] = nil
          end

          href = "https://codevalet.io/u/#{login}/#{redirect_path}"
        end

        redirect to(href)

      end

      redirect '/profile'
    end

    get '/_to/jenkins' do
      redirect to('/') unless env['warden'].user

      session[:jenkins] = true
      login = env['warden'].user.login
      redirect_path = 'securityRealm/commenceLogin?from=%2Fblue'
      href = "http://localhost:8080/#{redirect_path}"

      if production?
        if admin? && params['instance']
          login = params['instance']
          session[:admin_instance] = login
        end
        href = "https://codevalet.io/u/#{login}/#{redirect_path}"
      end
      redirect to(href)
    end

    get '/github/logout' do
      env['warden'].logout
      redirect '/'
    end
  end
end
