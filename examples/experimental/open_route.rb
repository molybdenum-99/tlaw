require 'pp'

$:.unshift 'lib'
require 'tlaw'
require 'geo/coord'

class OpenRouteService < TLAW::API
  define do
    base 'https://api.openrouteservice.org'

    param :api_key

    endpoint :directions do
      post_process { |res|
        res['route'] = res['routes'].first
      }
      param :coordinates, :to_a, keyword: false,
        format: ->(coords) { coords.map { |c| c.to_a.join(',') }.join('|') }
      param :profile
      param :geometry
      param :geometry_format
    end
  end
end

osm = OpenRouteService.new(api_key: ENV['OPEN_ROUTE_SERVICE'])
kharkiv = Geo::Coord.new(50.004444,36.231389)
kyiv = Geo::Coord.new(50.450000,30.523333)

pp osm.directions([kharkiv, kyiv], profile: 'driving-car', geometry_format: 'geojson')['route.segments'].first['steps']
