#!/usr/bin/env ruby
require_relative '../demo_base'
require_relative 'wunderground'

weather = TLAW::Examples::WUnderground.new(api_key: ENV['WUNDERGROUND'])

pp weather.city('Kharkiv', 'Ukraine', features: %i[astronomy tide])
