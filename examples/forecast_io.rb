module TLAW
  module Examples
    class ForecastIO < TLAW::API
      define do
        base 'https://api.forecast.io/forecast/{api_key}'

        desc %Q{
          The Forecast API allows you to look up the weather anywhere on
          the globe, returning (where available):

          * Current conditions
          * Minute-by-minute forecasts out to 1 hour
          * Hour-by-hour forecasts out to 48 hours
          * Day-by-day forecasts out to 7 days
        }

        docs 'https://developer.forecast.io/docs/v2'

        param :api_key, required: true,
          desc: 'Register at https://developer.forecast.io/register to obtain it'
        param :units, enum: %i[us si ca uk2 auto], default: :us,
          desc: %Q{
            Response units. Values:
            * `:us` is default;
            * `:si` is meters/celsius/hectopascals;
            * `:ca` is identical to si, except that `windSpeed` is in
              kilometers per hour.
            * `:uk2` is identical to si, except that `windSpeed` is in
              miles per hour, and `nearestStormDistance` and `visibility`
              are in miles, as in the US.
            * `auto` selects the relevant units automatically, based
              on geographic location.
          }

        param :lang, default: :en,
          desc: %Q{
            Return summary properties in the desired language. (2-letters code)
          }

        endpoint :forecast, '/{lat},{lng}' do
          desc %Q{Forecast for the next week.}

          docs 'https://developer.forecast.io/docs/v2#forecast_call'

          param :lat, :to_f, required: true, desc: 'Latitude'
          param :lng, :to_f, required: true, desc: 'Longitude'

          param :exclude, Array,
            desc: %Q{
              Exclude some number of data blocks from the API response.
              This is useful for reducing latency and saving cache space.
              Should be a list (without spaces) of any of the following:
              currently, minutely, hourly, daily, alerts, flags.
            }

          param :extended_hourly, field: :extend,
            enum: {false => nil, true => 'hourly'},
            desc: %Q{
              When present, return hourly data for the next seven days,
              rather than the next two.
            }
        end

        endpoint :time_machine, '/{lat},{lng},{at}' do
          desc %Q{
            Observed weather at a given time (for many places, up to 60
            years in the past).

            For future dates, returns numerical forecast for the next week
            and seasonal averages beyond that.
          }

          docs 'https://developer.forecast.io/docs/v2#time_call'

          param :lat, :to_f, required: true, desc: 'Latitude'
          param :lng, :to_f, required: true, desc: 'Longitude'
          param :at, :to_time, format: :to_i, required: true,
            desc: 'Date in past or future.'

          param :exclude, Array,
            desc: %Q{
              Exclude some number of data blocks from the API response.
              This is useful for reducing latency and saving cache space.
              Should be a list (without spaces) of any of the following:
              currently, minutely, hourly, daily, alerts, flags.
            }
        end

        post_process 'currently.time', &Time.method(:at)

        post_process_items('minutely.data') {
          post_process 'time', &Time.method(:at)
        }

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
    # TODO: The Forecast Data API supports HTTP compression.
    #   We heartily recommend using it, as it will make responses much
    #   smaller over the wire. To enable it, simply add an
    #   Accept-Encoding: gzip header to your request.
  end
end
