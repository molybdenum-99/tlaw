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
pp res
# {"latitude"=>40.7127,
#  "longitude"=>-74.0059,
#  "timezone"=>"America/New_York",
#  "offset"=>-5,
#  "currently.time"=>2017-02-23 19:06:50 +0200,
#  "currently.summary"=>"Overcast",
#  "currently.icon"=>"cloudy",
#  "currently.nearestStormDistance"=>362,
#  "currently.nearestStormBearing"=>179,
#  "currently.precipIntensity"=>0,
#  "currently.precipProbability"=>0,
#  "currently.temperature"=>12.57,
#  "currently.apparentTemperature"=>12.57,
#  "currently.dewPoint"=>10.42,
#  "currently.humidity"=>0.87,
#  "currently.windSpeed"=>2.03,
#  "currently.windBearing"=>188,
#  "currently.visibility"=>9.69,
#  "currently.cloudCover"=>0.95,
#  "currently.pressure"=>1012.11,
#  "currently.ozone"=>330.56,
#  "minutely.summary"=>"Overcast for the hour.",
#  "minutely.icon"=>"cloudy",
#  "minutely.data"=>
#   #<TLAW::DataTable[time, precipIntensity, precipProbability] x 61>,
#  "hourly.summary"=>"Light rain starting this evening.",
#  "hourly.icon"=>"rain",
#  "hourly.data"=>
#   #<TLAW::DataTable[time, summary, icon, precipIntensity, precipProbability, temperature, apparentTemperature, dewPoint, humidity, windSpeed, windBearing, visibility, cloudCover, pressure, ozone, precipType] x 169>,
#  "daily.summary"=>
#   "Light rain throughout the week, with temperatures falling to 12°C on Thursday.",
#  "daily.icon"=>"rain",
#  "daily.data"=>
#   #<TLAW::DataTable[time, summary, icon, sunriseTime, sunsetTime, moonPhase, precipIntensity, precipIntensityMax, precipIntensityMaxTime, precipProbability, precipType, temperatureMin, temperatureMinTime, temperatureMax, temperatureMaxTime, apparentTemperatureMin, apparentTemperatureMinTime, apparentTemperatureMax, apparentTemperatureMaxTime, dewPoint, humidity, windSpeed, windBearing, visibility, cloudCover, pressure, ozone] x 8>,
#  "flags.sources"=> ["darksky",  "lamp",  "gfs",  "cmc",  "nam",  "rap",  "rtma",  "sref",  "fnmoc",  "isd",  "madis",  "nearest-precip",  "nwspa"],
#  "flags.darksky-stations"=>["KDIX", "KOKX"],
#  "flags.lamp-stations"=> ["KBLM",  "KCDW",  "KEWR",  "KFRG",  "KHPN",  "KJFK",  "KLGA",  "KMMU",  "KNYC",  "KSMQ",  "KTEB"],
#  "flags.isd-stations"=> ["725020-14734",  "725025-94741",  "725030-14732",  "725033-94728",  "725060-99999",  "744860-94789",  "744976-99999",  "997271-99999",  "997272-99999",  "997743-99999",  "999999-14732",  "999999-14734",  "999999-14786",  "999999-94706",  "999999-94728",  "999999-94741"],
#  "flags.madis-stations"=> ["AU015",  "BATN6",  "C1099",  "C9714",  "D0486",  "D3216",  "D5729",  "D9152",  "E0405",  "E1296",  "E2876",  "KLGA",  "KNYC",  "KTEB",  "NJ12",  "ROBN4"],
#  "flags.units"=>"si"}

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
