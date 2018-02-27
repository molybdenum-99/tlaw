require 'pp'

$:.unshift '../lib'
require 'tlaw'

begin
  require 'dotenv'
  Dotenv.load
rescue LoadError
end
