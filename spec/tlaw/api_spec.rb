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
        before {
          endpoint.endpoint_name = :some_endpoint
          api.__send__(:add_endpoint, endpoint)
        }

        its(:constants) { is_expected.to include(:SomeEndpoint) }
        its(:instance_methods) { is_expected.to include(:some_endpoint) }
        its(:endpoints) { is_expected.to include(some_endpoint: endpoint) }
      end

      describe '.add_namespace' do
        let(:namespace) { Class.new(Namespace) }
        subject(:api) { Class.new(API) }
        before {
          namespace.namespace_name = :some_namespace
          api.__send__(:add_namespace, namespace)
        }

        its(:constants) { is_expected.to include(:SomeNamespace) }
        its(:instance_methods) { is_expected.to include(:some_namespace) }
        its(:namespaces) { is_expected.to include(some_namespace: namespace) }
      end
    end

    context 'real work' do
      let!(:api_class) {
        Class.new(API) do
          define do
            base 'http://api.example.com'

            endpoint :some_ep do
              param :foo
            end

            namespace :some_ns do
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

        it 'instantiates namespaces' do
          expect(api.namespaces[:some_ns]).to be_an Namespace
        end

        it 'parses and validates initial params'
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

    context 'documentation' do
      let(:api_class) {
        Class.new(API) do
          define do
            base 'http://api.example.com'

            param :api_key, required: true

            endpoint :some_ep do
              param :foo
            end

            namespace :some_ns do
            end
          end
        end
      }
      let(:api) { api_class.new(api_key: '123') }

      before { allow(api_class).to receive(:name).and_return('Dummy') }

      context '.inspect' do
        subject { api_class.inspect }

        it { is_expected.to eq '#<Dummy | create: Dummy.new(api_key:), docs: Dummy.describe>' }
      end

      context '#inspect' do
        subject { api.inspect }

        it { is_expected.to eq '#<Dummy(api_key: "123") namespaces: some_ns; endpoints: some_ep; docs: .describe>' }
      end

    end
  end
end
