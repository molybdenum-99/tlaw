require 'pp'

$:.unshift 'lib'
require 'tlaw'

class WorldBankClimate < TLAW::API
  define do
    base 'http://climatedataapi.worldbank.org/climateweb/rest/v1'

    {
      basin: :basinID,
      country: :country_iso3
    }.each do |namespace_name, param_name|
      namespace namespace_name do
        param param_name, keyword: false, required: true

        {
          :temperature => 'tas',
          :precipation => 'pr'
        }.each do |varname, var|
          namespace varname, path: '' do
            {
              monthly: 'mavg',
              annual: 'annualavg',
              monthly_anomaly: 'manom',
              annual_anomaly: 'annualanom'
            }.each do |typename, type|
              endpoint typename, path: "/#{type}/#{var}/{since}/{#{param_name}}.json" do
                param :since, keyword: true, required: true,
                  enum: {
                    1920 => '1920/1939',
                    1940 => '1940/1959',
                    1960 => '1960/1979',
                    1980 => '1980/1999',
                    2020 => '2020/2039',
                    2040 => '2040/2059',
                    2060 => '2060/2079',
                    2080 => '2080/2099',
                  }

                if typename.to_s.include?('monthly')
                  post_process_replace do |res|
                    {
                      'variable' => res.first['variable'],
                      'fromYear' => res.first['fromYear'],
                      'toYear' => res.first['toYear'],
                      'data' => TLAW::DataTable
                        .from_columns(
                          res.map { |r| r['gcm'] },
                          res.map { |r| r['monthVals'] }
                        )
                    }
                  end
                else
                  post_process_replace do |res|
                    {
                      'variable' => res.first['variable'],
                      'fromYear' => res.first['fromYear'],
                      'toYear' => res.first['toYear'],
                      'gcm' => res.map { |res| [res['gcm'], res['annualData'].first] }.to_h
                    }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

wbc = WorldBankClimate.new

pp wbc.country('ukr').temperature.annual(since: 1980)
pp wbc.country('ukr').precipation.monthly(since: 1980)['data']

