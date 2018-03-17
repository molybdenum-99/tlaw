$:.unshift File.expand_path('../../lib', __FILE__)

require 'tlaw'
require 'pp'

begin
  require 'dotenv'
  Dotenv.load
rescue LoadError
end
