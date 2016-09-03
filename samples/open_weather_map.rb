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

        post_process('weather', &:first)
        post_process('dt', &Time.method(:at))
        post_process('sys.sunrise', &Time.method(:at))
        post_process('sys.sunset', &Time.method(:at))

        # See http://openweathermap.org/weather-conditions#How-to-get-icon-URL
        post_process('weather.icon') { |i| "http://openweathermap.org/img/w/#{i}.png" }

        post_process_each('list', 'weather', &:first)
        post_process_each('list', 'dt', &Time.method(:at))
        post_process_each('list', 'sys.sunrise', &Time.method(:at))
        post_process_each('list', 'sys.sunset', &Time.method(:at))

        # See http://openweathermap.org/weather-conditions#How-to-get-icon-URL
        post_process_each('list', 'weather.icon') { |i| "http://openweathermap.org/img/w/#{i}.png" }

        CURRENT_WEATHER_ENDPOINTS = lambda do |*|
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

        namespace :current, path: '/weather',
          desc: %Q{
            Allows to obtain current weather at one place, designated
            by city, location or zip code. See also {#batch_current} for
            obtaining weather in several places at once.

            Docs: http://openweathermap.org/current
          },
          &CURRENT_WEATHER_ENDPOINTS

        namespace :find, path: '/find',
          desc: %Q{
            Allows to find some place (and weather in it) by set of input
            parameters.

            Docs: http://openweathermap.org/current#accuracy
          } do
            param :type, enum: %w[accurate like], default: 'accurate', keyword_argument: false

            instance_eval(&CURRENT_WEATHER_ENDPOINTS)

            post_process_each('list', 'weather', &:first)
            post_process_each('list', 'dt', &Time.method(:at))
            post_process_each('list', 'sys.sunrise', &Time.method(:at))
            post_process_each('list', 'sys.sunset', &Time.method(:at))
            post_process_each('list') { |e| e['coord'] = Geo::Coord.new(e['coord.lat'], e['coord.lon']) }
            post_process_each('list', 'coord.lat'){nil}
            post_process_each('list', 'coord.lon'){nil}

            # See http://openweathermap.org/weather-conditions#How-to-get-icon-URL
            post_process_each('list', 'weather.icon') { |i| "http://openweathermap.org/img/w/#{i}.png" }
          end

        # http://openweathermap.org/current#cities
        namespace :batch_current, path: '' do
          endpoint :bbox, path: '/box/city?bbox={lon_left},{lat_bottom},{lon_right},{lat_top}'

          endpoint :around, path: '/find?lat={lat}&lon={lng}' do
            param :lat, :to_f, required: true
            param :lng, :to_f, required: true
            param :cnt, :to_i
          end

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

            post_process_each('list', 'weather', &:first)
            post_process_each('list', 'dt', &Time.method(:at))
            post_process_each('list', 'dt_txt'){nil}
          end
        end
      end
    end
  end
end
