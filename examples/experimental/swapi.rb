require 'pp'

$:.unshift 'lib'
require 'tlaw'

class SWAPI < TLAW::API
  define do
    base 'http://swapi.co/api'

    namespace :people do
      endpoint :all, ''
      endpoint :[], '/{id}/'
      endpoint :search, '/?search={query}'
    end

    namespace :species do
      endpoint :all, ''
      endpoint :[], '/{id}/'
      endpoint :search, '/?search={query}'
    end
  end
end

s = SWAPI.new

pp s.people.search('r2')['results'].first
pp s.species[2]
