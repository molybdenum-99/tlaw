require 'geo/coord'

module TLAW
  module Samples
    class OpenWeatherMap < TLAW::API
      define do
        desc %Q{
          API for [OpenWeatherMap](http://openweathermap.org/). Only parts
          available for free are implemented (as only them could be tested).

          See full docs at http://openweathermap.org/api
        }
        base 'http://api.openweathermap.org/data/2.5'

        param :appid, required: true, desc: 'You need to receive it at http://openweathermap.org/appid (free)'
        param :lang, default: 'en',
          desc: %Q{Language of API responses (affects weather description only).
                   See http://openweathermap.org/current#multi for list of supported languages.}

        param :units, enum: %w[standard metric imperial], default: 'standard',
          desc: 'Units for temperature and other values. Standard is Kelvin.'

        WEATHER_POST_PROCESSOR = lambda do |*|
          # Most of the time there is exactly one weather item...
          # ...but sometimes there are two. So, flatterning them looks
          # more reasonable than having DataTable of 1-2 rows.
          post_process { |h|
            h['weather2'] = h['weather'].last if h['weather'] && h['weather'].count > 1
          }
          post_process('weather', &:first)

          post_process('dt', &Time.method(:at))
          post_process('dt_txt') { nil } # TODO: we need cleaner way to say "remove this"
          post_process('sys.sunrise', &Time.method(:at))
          post_process('sys.sunset', &Time.method(:at))

          post_process { |e|
            e['coord'] = Geo::Coord.new(e['coord.lat'], e['coord.lon']) if e['coord.lat'] && e['coord.lon']
          }
          post_process('coord.lat') { nil }
          post_process('coord.lon') { nil }

          # See http://openweathermap.org/weather-conditions#How-to-get-icon-URL
          post_process('weather.icon') { |i| "http://openweathermap.org/img/w/#{i}.png" }
        end

        # For endpoints returning weather in one place
        instance_eval(&WEATHER_POST_PROCESSOR)

        # For endpoints returning list of weathers (forecast or several
        # cities).
        post_process_items('list', &WEATHER_POST_PROCESSOR)

        namespace :current, path: '/weather',
          desc: %Q{
            Allows to obtain current weather at one place, designated
            by city, location or zip code. See also {#batch_current} for
            obtaining weather in several places at once.

            Docs: http://openweathermap.org/current
          } do

          endpoint :city, path: '?q={city}{,country_code}' do
            desc %Q{
              Current weather by city name (with optional country code
              specification).

              Docs: http://openweathermap.org/current#name
            }

            param :city, required: true, desc: 'City name'
            param :country_code, desc: 'ISO 3166 2-letter country code'
          end

          endpoint :city_id, path: '?id={city_id}' do
            desc %Q{
              Current weather by city id. Recommended by OpenWeatherMap
              docs.

              List of city ID city.list.json.gz can be downloaded at
              http://bulk.openweathermap.org/sample/

              Docs: http://openweathermap.org/current#cityid
            }

            param :city_id, required: true, desc: 'City ID (as defined by OpenWeatherMap)'
          end

          endpoint :location, path: '?lat={lat}&lon={lng}' do
            desc %Q{
              Current weather by geographic coordinates.

              Docs: http://openweathermap.org/current#geo
            }

            param :lat, :to_f, required: true, desc: 'Latitude'
            param :lng, :to_f, required: true, desc: 'Longitude'
          end

          endpoint :zip, path: '?zip={zip}{,country_code}' do
            desc %Q{
              Current weather by ZIP code (with optional country code
              specification).

              Docs: http://openweathermap.org/current#zip
            }

            param :zip, required: true, desc: 'ZIP code'
            param :country_code, desc: 'ISO 3166 2-letter country code'
          end
        end

        namespace :find,
          desc: %Q{
            Allows to find some place (and weather in it) by set of input
            parameters.

            Docs: http://openweathermap.org/current#accuracy
          } do

            endpoint :by_name, path: '?q={start_with}{,country_code}' do
              desc %Q{
                Looks for cities by beginning of their names.

                Docs: http://openweathermap.org/current#accuracy
              }

              param :start_with, required: true, desc: 'Beginning of city name'
              param :country_code, desc: 'ISO 3166 2-letter country code'

              param :cnt, :to_i, range: 1..50, default: 10,
                desc: 'Max number of results to return'

              # TODO: param :accurate, enum: {true => 'accurate', false => 'like'}
              param :type, enum: %w[accurate like],
                    default: 'accurate', keyword_argument: false,
                    desc: %Q{Accuracy level of result.
                     'accurate' returns exact match values.
                     'like' returns results by searching for that substring.
                    }
            end

            endpoint :around, path: '?lat={lat}&lon={lng}' do
              desc %Q{
                Looks for cities around geographical coordinates.

                Docs: http://openweathermap.org/current#cycle
              }

              param :lat, :to_f, required: true
              param :lng, :to_f, required: true

              param :cnt, :to_i, range: 1..50, default: 10,
                desc: 'Max number of results to return'

              # TODO: cluster
            end

            # Real path is api/bbox/city - not inside /find, but logically
            # we want to place it here
            endpoint :inside, path: '/../box/city?bbox={lng_left},{lat_bottom},{lng_right},{lat_top}' do
              desc %Q{
                Looks for cities inside specified rectangle zone.

                Docs: http://openweathermap.org/current#rectangle
              }

              param :lat_top, :to_f, required: true, keyword_argument: true
              param :lat_bottom, :to_f, required: true, keyword_argument: true
              param :lng_left, :to_f, required: true, keyword_argument: true
              param :lng_right, :to_f, required: true, keyword_argument: true

              # TODO: cluster
            end
          end

        # http://openweathermap.org/current#cities
        namespace :batch_current, path: '' do

          endpoint :group, path: '/group?id={city_ids}' do
            param :city_ids, :to_a, required: true
          end
        end

        # http://openweathermap.org/forecast5
        namespace :forecast, path: '/forecast' do
          # TODO: forecast{/daily}, param :daily, values: {true => 'daily', false => nil}
          endpoint :city, path: '?q={city}{,country_code}' do
            param :city, required: true, keyword_argument: false
            param :country_code
          end
        end
      end
    end
  end
end
