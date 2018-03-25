require 'pp'

$:.unshift 'lib'
require 'tlaw'

class Earthquake < TLAW::API
  define do
    base 'http://earthquake.usgs.gov/fdsnws/event/1'

    endpoint :count, '/count?format=geojson' do
      param :starttime, Date, format: ->(d) { d.strftime('%Y-%m-%d') }
      param :endtime, Date, format: ->(d) { d.strftime('%Y-%m-%d') }
    end

    endpoint :query, '/query?format=geojson' do
      param :starttime, Date, format: ->(d) { d.strftime('%Y-%m-%d') }
      param :endtime, Date, format: ->(d) { d.strftime('%Y-%m-%d') }
      param :minmagnitude, :to_i
    end
  end
end


#/query?format=geojson&starttime=2001-01-01&endtime=2014-01-02

e = Earthquake.new
res = e.query(starttime: Date.parse('2000-01-01'), endtime: Date.parse('2017-01-02'), minmagnitude: 9)
pp res['features'].count
pp res['features'].first
