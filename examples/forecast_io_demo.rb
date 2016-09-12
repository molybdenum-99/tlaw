#!/usr/bin/env ruby
require_relative 'demo_base'
require_relative 'forecast_io'

# This wrapper demo demonstrates that even a simple (one call, several
# params) API could benefit from TLAW by param types checking &
# sky-level discoverability.

p TLAW::Examples::ForecastIO
# #<TLAW::Examples::ForecastIO: call-sequence: TLAW::Examples::ForecastIO.new(api_key:, units: :us, lang: :en); endpoints: forecast, time_machine; docs: .describe>

p TLAW::Examples::ForecastIO.describe
# TLAW::Examples::ForecastIO.new(api_key:, units: :us, lang: :en)
#   The Forecast API allows you to look up the weather anywhere on
#   the globe, returning (where available):
#
#   * Current conditions
#   * Minute-by-minute forecasts out to 1 hour
#   * Hour-by-hour forecasts out to 48 hours
#   * Day-by-day forecasts out to 7 days
#
#   Docs: https://developer.forecast.io/docs/v2
#
#   @param api_key Register at https://developer.forecast.io/register to obtain it
#   @param units
#     Response units. Values:
#     * `:us` is default;
#     * `:si` is meters/celsius/hectopascals;
#     * `:ca` is identical to si, except that `windSpeed` is in
#     kilometers per hour.
#     * `:uk2` is identical to si, except that `windSpeed` is in
#     miles per hour, and `nearestStormDistance` and `visibility`
#     are in miles, as in the US.
#     * `auto` selects the relevant units automatically, based
#     on geographic location.
#
#     Possible values: :us, :si, :ca, :uk2, :auto (default = :us)
#   @param lang
#     Return summary properties in the desired language. (2-letters code)
#      (default = :en)
#
#   Endpoints:
#
#   .forecast(lat, lng, exclude: nil, extended_hourly: nil)
#     Forecast for the next week.
#
#   .time_machine(lat, lng, at, exclude: nil)
#     Observed weather at a given time (for many places, up to 60
#     years in the past).

# You need to create key here: https://developer.forecast.io/register
# And run the script this way:
#
#    FORECAST_IO={your_id} examples/forecast_io_demo.rb
#

weather = TLAW::Examples::ForecastIO
  .new(api_key: ENV['FORECAST_IO'], units: :si)

res = weather.forecast(40.7127, -74.0059, extended_hourly: true)
pp res['minutely.data'].first
# {"time"=>2016-09-12 21:20:00 +0300,
#  "precipIntensity"=>0,
#  "precipProbability"=>0}

res = weather.time_machine(49.999892, 36.242392, Date.parse('2020-02-01'))
pp res['daily.data'].columns('time', 'temperatureMin', 'temperatureMax', 'dewPoint', 'moonPhase').first
# {"time"=>2020-02-01 00:00:00 +0200,
#  "temperatureMin"=>-6.61,
#  "temperatureMax"=>-4.37,
#  "dewPoint"=>-7.7,
#  "moonPhase"=>0.23}
