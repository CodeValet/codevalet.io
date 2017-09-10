#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/app')

ENV['RACK_ENV'] ||= 'development'

require 'raven'
require 'server'

# Skip over Sinatra entirely for static assets
use Rack::Static, :urls => ['/css', '/img', '/js'], :root => 'assets'
use Raven::Rack

run CodeValet::Server
