require 'pp'

$:.unshift 'lib'
require 'tlaw'

class CurrencyLayer < TLAW::API
  define do
    base 'http://apilayer.net/api/'

    param :access_key, required: true

    endpoint :live do
      param :currencies, Array
    end

    endpoint :historical do
      param :date, :to_date, required: :true, keyword: false, format: ->(d) { d.strftime('%Y-%m-%d') }
      param :currencies, Array
    end
  end
end

cur = CurrencyLayer.new(access_key: ENV['CURRENCYLAYER'])

pp cur.historical(Date.parse('2016-01-01'), currencies: %w[UAH])
