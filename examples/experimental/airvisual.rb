require 'pp'

$:.unshift 'lib'
require 'tlaw'

class AirVisual < TLAW::API
  define do
    base 'http://api.airvisual.com/v1'
    param :key, required: true

    endpoint :nearest, '/nearest?lat={latitude}&lon={longitude}' do
    end
  end
end

av = AirVisual.new(key: ENV['AIRVISUAL'])
pp av.nearest(50.004444, 36.231389)
