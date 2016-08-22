module TLAW
  describe API do
    context 'definition' do
      describe '.define' do
      end

      describe '.add_param' do
      end

      describe '.add_endpoint' do
        let(:endpoint) { Class.new(Endpoint) }
        subject(:namespace) { Class.new(Namespace) }
        before {
          endpoint.endpoint_name = :some_endpoint
          namespace.__send__(:add_endpoint, endpoint)
        }

        its(:constants) { is_expected.to include(:SomeEndpoint) }
        its(:instance_methods) { is_expected.to include(:some_endpoint) }
        its(:endpoints) { is_expected.to include(some_endpoint: endpoint) }
      end
    end

    context 'instance' do
      let(:endpoint_class) {
        Class.new(Endpoint) {
          self.endpoint_name = :some_ep
          self.url = 'https://api.example.com/ns/some_ep'
          self.add_param :foo
        }
      }

      let!(:namespace_class) {
        Class.new(Namespace).tap { |c|
          c.base_url = 'https://api.example.com/ns'
          c.add_endpoint endpoint_class
        }
      }
      let(:initial_params) { {} }

      let(:api) { instance_double('TLAW::API', initial_param: initial_params) }

      subject(:namespace) { namespace_class.new(api)  }

      describe '#initialize' do
        it 'instantiates endpoints' do
          expect(namespace.endpoints[:some_ep]).to be_an Endpoint
        end
      end

      describe '#<endpoint>' do
        it 'calls proper endpoint' do
          expect(namespace.endpoints[:some_ep]).to receive(:call).with(foo: 'bar')
          namespace.some_ep(foo: 'bar')
        end

        context 'initial params' do
          let(:initial_params) { {apikey: 'foo'} }

          it 'adds them to call' do
            expect(namespace.endpoints[:some_ep]).to receive(:call).with(foo: 'bar', apikey: 'foo')
            namespace.some_ep(foo: 'bar')
          end
        end

      end

      context 'documentation' do
        before { allow(namespace_class).to receive(:name).and_return('SomeNamespace') }
        describe '#inspect' do
          subject { namespace.inspect }

          it { is_expected.to eq '#<SomeNamespace endpoints: some_ep; docs: .describe>' }
        end
      end
    end
  end
end
