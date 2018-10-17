require 'pp'

$:.unshift 'lib'
require 'tlaw'

# https://www.quandl.com/docs/api?json#get-data
class Quandl < TLAW::API
  define do
    base 'https://www.quandl.com/api/v3'

    param :api_key, required: true

    namespace :databases do
      endpoint :list, path: '.json' do
        param :per_page, :to_i
      end

      endpoint :search, path: '.json?query={query}' do
        param :query, required: true
      end

      namespace :[], path: '/{code}' do
        endpoint :meta, path: '.json'
        endpoint :codes, path: '/codes.csv'

        namespace :datasets, path: '/../../datasets/{code}' do
          endpoint :[], path: '/{dataset_code}.json' do
            param :code

            post_process { |h|
              columns = h['dataset.column_names']
              h['dataset.data'] = h['dataset.data']
                .map { |r| columns.zip(r).to_h }
            }

            post_process_items 'dataset.data' do
              post_process 'Date', &Date.method(:parse)
            end
          end

        end
      end
    end
  end
end

q = Quandl.new(api_key: ENV['QUANDL'])

#pp q.databases.search('ukraine')['databases'].first
pp q.databases['WIKI'].datasets['AAPL', code: 'WIKI']['dataset.data']['Date'].min
#pp q.databases['WIKI'].datasets.endpoint(:[]).construct_template
