module TLAW
  describe API do
    context 'definition' do
      describe '.define' do
      end

      describe '.add_param' do
      end

      describe '.add_endpoint' do
        let(:endpoint) { Class.new(Endpoint) }
        subject(:api) { Class.new(API) }
        before { api.__send__(:add_endpoint, :some_endpoint, endpoint) }

        its(:constants) { is_expected.to include(:SomeEndpoint) }
        its(:instance_methods) { is_expected.to include(:some_endpoint) }
        its(:endpoints) { is_expected.to include(some_endpoint: endpoint) }
      end
    end

    context 'real work' do
      let!(:api_class) {
        Class.new(API) do
          define do
            base 'http://api.example.com'

            endpoint :some_ep do
            end
          end
        end
      }

      let(:initial_params) { {} }
      subject(:api) { api_class.new(initial_params)  }

      describe '#initialize' do
        it 'instantiates endpoints' do
          expect(api.endpoints[:some_ep]).to be_an Endpoint
        end

        it 'parses and validates initial params'
      end

      describe '#call' do
        it 'joins path with base URL and calls web' do
          expect { api.call('wtf?q=Why') }
            .to get_webmock('http://api.example.com/wtf?q=Why')
            .and_return({test: 'me'}.to_json)
        end

        let(:deep_hash) {
          {
            response: {status: 200, message: 'OK'},
            data: {field1: 'foo', field2: {bar: 1}}
          }
        }

        it 'parses response & flatterns it' do
          stub_request(:get, 'http://api.example.com/wtf?q=Why')
            .to_return(body: deep_hash.to_json)

          expect(api.call('wtf?q=Why'))
            .to eq(
              'response.status' => 200,
              'response.message' => 'OK',
              'data.field1' => 'foo',
              'data.field2.bar' => 1
            )
        end
      end

      describe '#<endpoint>' do
        it 'calls proper endpoint' do
          expect(api.endpoints[:some_ep]).to receive(:call).with(foo: 'bar')
          api.some_ep(foo: 'bar')
        end

        context 'initial params' do
          let(:initial_params) { {apikey: 'foo'} }

          it 'adds them to call' do
            expect(api.endpoints[:some_ep]).to receive(:call).with(foo: 'bar', apikey: 'foo')
            api.some_ep(foo: 'bar')
          end
        end
      end
    end
  end
end
