require 'pp'

$:.unshift 'lib'
require 'tlaw'

module TLAW
  module Examples
    class ForecastIO < TLAW::API
      define do
        base 'https://api.forecast.io/forecast/{api_key}'

        param :api_key, required: true
        param :units, enum: %i[us si ca uk2 auto]
        param :exclude, Array
        param :lang

        # synopsys: forecast(location)
        endpoint :forecast, path: '/{lat},{lng}' do
          param :lat, :to_f, required: true
          param :lng, :to_f, required: true

          param :extended_hourly, field: :extend,
            enum: {false => nil, true => 'hourly'}
        end

        # synopsys: time_machine(location, time)
        endpoint :time_machine, path: '/{lat},{lng},{at}' do
          param :lat, :to_f, required: true
          param :lng, :to_f, required: true
          param :at, :to_time, format: :to_i, required: true, keyword_argument: false
        end

        post_process 'currently.time', &Time.method(:at)

        post_process_items('hourly.data') {
          post_process 'time', &Time.method(:at)
        }

        post_process_items('daily.data') {
          post_process 'time', &Time.method(:at)
          post_process 'sunriseTime', &Time.method(:at)
          post_process 'sunsetTime', &Time.method(:at)
        }
      end
    end

    # TODO: X-Forecast-API-Calls header is useful!
  end
end
