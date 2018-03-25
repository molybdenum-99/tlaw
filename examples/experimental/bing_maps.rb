require 'pp'

$:.unshift 'lib'
require 'tlaw'

#http://docs.themoviedb.apiary.io/#reference/movies/movielatest

class BingMaps < TLAW::API
  define do
    base 'http://dev.virtualearth.net/REST/v1'
    param :key, required: true

    namespace :locations, '/Locations' do
      endpoint :query, '?q={q}'
    end
  end
end

maps = BingMaps.new(key: ENV['BING_MAPS'])

pp maps.locations.query('Харків, Олексіівська 33а')['resourceSets'].first
