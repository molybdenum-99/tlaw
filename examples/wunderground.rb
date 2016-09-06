module TLAW
  module Examples
    class WUnderground < TLAW::API
      define do
        base 'http://api.wunderground.com/api/{api_key}{/features}{/lang}/q'

        param :api_key, required: true
        param :lang, format: ->(l) { "lang:#{l}" }

        FEATURES = %i[
          alerts
          almanac
          astronomy
          conditions
          currenthurricane
          forecast
          forecast10day
          geolookup
          hourly
          hourly10day
          rawtide
          tide
          webcams
          yesterday
        ].freeze

        ALL_FEATURES = %i[
          history
          planner
        ]

        COMMON_PARAMS = lambda do |*|
          param :features, Array #enum: FEATURES # TODO: Array+enum
          param :pws, enum: {false => 0, true => 1}
          param :bestfct, enum: {false => 0, true => 1}
        end

        endpoint :city, path: '{/country}/{city}.json' do
          param :city, required: true

          instance_eval(&COMMON_PARAMS)
        end

        endpoint :us_zipcode do
        end

        endpoint :location do
        end

        endpoint :airport do
        end

        endpoint :pws do
        end

        endpoint :geo_ip do
        end
      end
    end
  end
end
