require 'pp'

$:.unshift 'lib'
require 'tlaw'

require 'geo/coord'

#http://www.geonames.org/export/web-services.html
#http://www.geonames.org/export/credits.html
#http://www.geonames.org/export/ws-overview.html

class GeoNames < TLAW::API
  define do
    base 'http://api.geonames.org'

    param :username, required: true
    param :lang

    ERROR_CODES = {
      10 => 'Authorization Exception',
      11 => 'record does not exist',
      12 => 'other error',
      13 => 'database timeout',
      14 => 'invalid parameter',
      15 => 'no result found',
      16 => 'duplicate exception',
      17 => 'postal code not found',
      18 => 'daily limit of credits exceeded',
      19 => 'hourly limit of credits exceeded',
      20 => 'weekly limit of credits exceeded',
      21 => 'invalid input',
      22 => 'server overloaded exception',
      23 => 'service not implemented',
    }

    post_process do |response|
      if response['status.value']
        fail "#{ERROR_CODES[response['status.value']]}: #{response['status.message']}"
      end
    end

    namespace :search, path: '/searchJSON' do
      endpoint :query, path: '?q={q}' do
        param :q, required: true
        param :country #TODO: country=FR&country=GP
      end

      endpoint :name, path: '?name={name}' do
        param :name, required: true
      end

      endpoint :name_equals, path: '?name_equals={name}' do
        param :name, required: true
      end
    end

    namespace :postal_codes, path: '' do
      endpoint :countries, path: '/postalCodeCountryInfoJSON'
    end

    namespace :near, path: '' do
      param :lat, keyword_argument: false
      param :lng, keyword_argument: false

      endpoint :ocean, path: '/oceanJSON'
      endpoint :country, path: '/countryCodeJSON'
      endpoint :weather, path: '/findNearByWeatherJSON'
      endpoint :extended, path: '/extendedFindNearby', xml: true do
        post_process_replace { |res| res['geonames.geoname'] }
      end
    end

    namespace :weather, path: '' do
      endpoint :near, path: '/findNearByWeatherJSON?lat={lat}&lng={lng}'
    end

    endpoint :earthquakes, path: '/earthquakesJSON' do
      param :north
      param :south
      param :east
      param :west

      post_process_items 'earthquakes' do
        post_process 'datetime', &Time.method(:parse)
        post_process { |h| h['coord'] = Geo::Coord.new(h['lat'], h['lng']) }
      end
    end
  end
end

gn = GeoNames.new(username: 'realitygeo')

#pp gn.search.name_equals('Kharkiv')['geonames'].to_a
#pp gn.postal_codes.countries['geonames'].detect { |r| r['countryName'].include?('Thai') }
#pp gn.near(50.004444, 36.231389).country
#pp gn.near(50.004444, 36.231389).ocean
pp gn.near(50.004444, 36.231389).extended.to_a
#pp gn.near(50.004444, 36.231389).weather
#pp gn.weather.near(50.004444, 36.231389)

#pp gn.earthquakes(north: 44.1, south: -9.9, east: -22.4, west: 55.2)['earthquakes'].to_a
# => to worldize!
