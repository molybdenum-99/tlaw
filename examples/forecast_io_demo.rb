#!/usr/bin/env ruby
require_relative 'demo_base'
require_relative 'forecast_io'

weather = TLAW::Examples::ForecastIO
  .new(api_key: ENV['FORECAST_IO'], units: :si)

res = weather.forecast(40.7127, -74.0059, extended_hourly: true)
#pp res
#pp res['minutely.data'].first


#res = weather.time_machine(49.999892, 36.242392, Date.parse('2011-02-01'))
#pp res['daily.data'].columns('time', 'moonPhase').to_a

#pp weather.endpoints[:forecast].describe

res = weather.time_machine(49.999892, 36.242392, Date.parse('2020-02-01'))
pp res['daily.data']
pp res['daily.data'].columns('time', 'temperatureMin', 'temperatureMax', 'dewPoint', 'moonPhase').to_a
