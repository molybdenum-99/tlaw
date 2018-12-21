module TLAW
  module Examples
    class WUnderground < TLAW::API
      define do
        base 'http://api.wunderground.com/api/{api_key}{/features}{/lang}/q'

        param :api_key, required: true
        param :lang, format: 'lang:#%s'.method(:%)

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

        shared_def :common_params do
          param :features, Array, format: ->(a) { a.join('/') }
            #TODO: enum: FEATURES -- doesn't work with Array
          param :pws, enum: {false => 0, true => 1}
          param :bestfct, enum: {false => 0, true => 1}
        end

        post_process { |h|
          h.key?('response.error.type') and fail h['response.error.type']
        }

        endpoint :city, '{/country}/{city}.json' do
          param :city, required: true

          use_def :common_params
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
