#!/usr/bin/env ruby
require_relative 'demo_base'
require_relative 'forecast_io'

weather = TLAW::Examples::ForecastIO
  .new(api_key: ENV['FORECAST_IO'], units: :si)

pp weather.forecast(49.999892, 36.242392, extended_hourly: true)


res = weather.time_machine(49.999892, 36.242392, Date.parse('2011-02-01'))
pp res['daily.data'].columns('time', 'moonPhase').to_a
