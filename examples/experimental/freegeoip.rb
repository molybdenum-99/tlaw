require 'pp'

$:.unshift 'lib'
require 'tlaw'


class FreeGeoIP < TLAW::API
  define do
    base 'http://freegeoip.net/json/'

    endpoint :here, ''
    endpoint :at, '/{ip}'
  end
end

fgi = FreeGeoIP.new
pp fgi.here
