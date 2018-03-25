require 'pp'

$:.unshift 'lib'
require 'tlaw'

#https://www.apixu.com/doc/

class APIXU < TLAW::API
  define do
    base 'http://api.apixu.com/v1'
    param :key, required: true
    param :lang

    namespace :current, '/current.json' do
      endpoint :city, '?q={city}' do
        param :city, :to_s, required: true
      end
    end

    namespace :forecast, '/forecast.json' do
      endpoint :city, '?q={city}' do
        param :city, :to_s, required: true
        param :days, :to_i
        param :dt, Date, format: ->(dt) { dt.strftime('%Y-%m-%d') }
      end
    end
  end
end

apixu = APIXU.new(key: ENV['APIXU'], lang: 'uk')
pp apixu.current.city('Kharkiv')
#res = apixu.forecast.city('Odesa', days: 10, dt: Date.parse('2017-07-03'))
#pp res['forecast.forecastday']['day.mintemp_c']
#pp res['forecast.forecastday']['day.maxtemp_c']
