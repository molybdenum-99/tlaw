require_relative '../demo_base'

class OpenExchangeRate < TLAW::API
  define do
    base 'https://openexchangerates.org/api'

    param :app_id, required:  true

    post_process { |h|
      h['rates'] = h
        .select { |k, v| k.start_with?('rates.') }
        .map { |k, v| {'to' => k.sub('rates.', ''), 'rate' => v} }

      h.reject! { |k, v| k.start_with?('rates.') }
    }
    post_process 'timestamp', &Time.method(:at)

    endpoint :currencies, path: '/currencies.json'

    endpoint :latest, path: '/latest.json'

    endpoint :historical, path: '/historical/{date}.json' do
      param :date, :to_date, format: ->(v) { v.strftime('%Y-%m-%d') }
    end

    endpoint :usage, path: '/usage.json'
  end
end

api = OpenExchangeRate.new(app_id: ENV['OPEN_EXCHANGE_RATES'])

#pp api.latest['rates'].first(3)
#pp api.historical(Date.parse('2016-05-01'))['rates'].detect { |r| r['to'] == 'INR' } #, base: 'USD')
#pp api.convert(100, 'INR', 'USD')
#pp api.usage
pp api.latest['rates'].detect { |r| r['to'] == 'INR' }
