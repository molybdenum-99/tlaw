require 'pp'

$:.unshift 'lib'
require 'tlaw'

class Nominatim < TLAW::API
  define do
    base 'http://nominatim.openstreetmap.org'

    param :lang, field: 'accept%2Dlanguage'

    namespace :search, '/search?format=json' do
      endpoint :query, '' do
        param :query, field: :q, keyword: false

        param :details, field: :addressdetails, enum: {false => 0, true => 1}
        param :geojson, field: :polygon_geojson, enum: {false => 0, true => 1}
        param :tags, field: :extratags, enum: {false => 0, true => 1}
        param :limit
      end

      endpoint :address, '' do
        param :city
        param :country
        param :street
        param :postalcode
        param :details, field: :addressdetails, enum: {false => 0, true => 1}
        param :geojson, field: :polygon_geojson, enum: {false => 0, true => 1}
        param :tags, field: :extratags, enum: {false => 0, true => 1}
      end
    end

    endpoint :geocode, '/reverse?format=json' do
      param :lat, :to_f, keyword: false
      param :lng, :to_f, field: :lon, keyword: false
    end

    endpoint :lookup, '/lookup?format=json&osm_ids={ids}' do
      param :ids, splat: true
    end
  end
end

n = Nominatim.new(lang: 'en')

#pp n.search.address(country: 'Ukraine', city: 'Kharkiv', street: '33a Oleksiivska', details: true, geojson: true, tags: true).first
# pp n.search.query('New York, Times Square', details: true, tags: true, limit: 1).to_a
#pp n.geocode(50.0403843, 36.203339684)
#pp n.search.query('Pharmacy, Kharkiv', details: true, tags: true, limit: 100)['address.pharmacy'].compact
#pp n.geocode(49.9808, 36.2527)
# pp n.search.address(country: 'Thailand', city: 'Bangkok', details: true, tags: true).to_a
pp n.search.query('Oleksiivska 33a, Kharkiv, Ukraine').to_a