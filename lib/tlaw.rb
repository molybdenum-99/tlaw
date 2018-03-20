require 'backports/2.5.0/kernel/yield_self'
require 'open-uri'
require 'json'
require 'addressable/uri'
require 'addressable/template'

# TLAW is a framework for creating API wrappers for get-only APIs (like
# weather, geonames and so on) or subsets of APIs (like getting data from
# Twitter).
#
# Short example:
#
# ```ruby
# # Definition:
# class OpenWeatherMap < TLAW::API
#   param :appid, required: true
#
#   namespace :current, '/weather' do
#     endpoint :city, '?q={city}{,country_code}' do
#       param :city, required: true
#     end
#   end
# end
#
# # Usage:
# api = OpenWeatherMap.new(appid: '<yourappid>')
# api.current.weather('Kharkiv')
# # => {"weather.main"=>"Clear",
# #  "weather.description"=>"clear sky",
# #  "main.temp"=>8,
# #  "main.pressure"=>1016,
# #  "main.humidity"=>81,
# #  "dt"=>2016-09-19 08:30:00 +0300,
# #  ...}
#
# ```
#
# Refer to [README](./file/README.md) for reasoning about why you need it and links to
# more detailed demos, or start reading YARD docs from {API} and {DSL}
# modules.
module TLAW
end

require_relative 'tlaw/util'
require_relative 'tlaw/data_table'

require_relative 'tlaw/params'

require_relative 'tlaw/api_path'
require_relative 'tlaw/endpoint'
require_relative 'tlaw/namespace'
require_relative 'tlaw/api'

require_relative 'tlaw/processors'

require_relative 'tlaw/dsl'
