require 'pp'

$:.unshift 'lib'
require 'tlaw'

class OpenStreetMap < TLAW::API
  define do
    base 'http://api.openstreetmap.org/api/0.6'

    endpoint :relation, '/relation/{id}', xml: true
  end
end

osm = OpenStreetMap.new

pp osm.relation(1543125)["osm.relation.tag"].to_a
