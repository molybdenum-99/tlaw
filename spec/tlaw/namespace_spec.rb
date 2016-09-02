module TLAW
  describe Namespace do
    context 'definition' do
      subject(:namespace) {
        Class.new(described_class).tap { |c|
          c.base_url = 'https://example.com/ns'
        }
      }

      describe '.define' do
      end

      its(:param_set) { is_expected.to be_a ParamSet }

      describe '.add_endpoint' do
        let(:endpoint) {
          Class.new(Endpoint).tap { |c|
            c.symbol = :some_endpoint
            c.path = '/ep'
          }
        }

        before {
          namespace.add_endpoint(endpoint)
        }

        its(:constants) { is_expected.to include(:SomeEndpoint) }
        its(:instance_methods) { is_expected.to include(:some_endpoint) }
        its(:endpoints) { is_expected.to include(some_endpoint: endpoint) }

        context 'updates endpoint' do
          subject { endpoint }

          its(:'param_set.parent') { is_expected.to eq namespace.param_set }
          its(:base_url) { is_expected.to eq 'https://example.com/ns/ep' }
        end
      end

      describe '.add_namespace' do
        let(:child) {
          Class.new(Namespace).tap { |c|
            c.symbol = :some_namespace
            c.path = '/ns2'
          }
        }
        before {
          namespace.add_namespace(child)
        }

        its(:constants) { is_expected.to include(:SomeNamespace) }
        its(:instance_methods) { is_expected.to include(:some_namespace) }
        its(:namespaces) { is_expected.to include(some_namespace: child) }

        context 'updates child' do
          subject { child }

          its(:'param_set.parent') { is_expected.to eq namespace.param_set }
          its(:base_url) { is_expected.to eq 'https://example.com/ns/ns2' }
        end
      end
    end

    context 'instance' do
      let(:endpoint_class) {
        Class.new(Endpoint).tap { |c|
          c.symbol = :some_ep
          c.path = '/some_ep'
          c.param_set.add :foo
        }
      }

      let(:child_class) {
        Class.new(described_class).tap { |c|
          c.symbol = :child_ns
          c.path = '/ns2'
        }
      }

      let!(:namespace_class) {
        Class.new(described_class).tap { |c|
          c.symbol = :some_ns
          c.base_url = 'https://api.example.com/ns'
          c.add_endpoint endpoint_class
          c.add_namespace child_class
          c.param_set.add :apikey
        }
      }
      let(:initial_params) { {} }

      subject(:namespace) { namespace_class.new(initial_params)  }

      describe '#initialize' do
        it 'instantiates endpoints' do
          expect(namespace.endpoints[:some_ep]).to be_an Endpoint
        end

        let(:initial_params) { {apikey: '111'} }

        it 'instantiates children' do
          expect(namespace.namespaces[:child_ns]).to be_a Namespace
          expect(namespace.namespaces[:child_ns].initial_params).to eq initial_params
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

          it { is_expected.to eq '#<SomeNamespace namespaces: child_ns; endpoints: some_ep; docs: .describe>' }
        end

        describe '#describe' do # this describe just describes the describe. Problems, officer?
          before {
            namespace_class.description = "It's namespace, you know?..\nIt is ok."
          }
          subject { namespace.describe.to_s }

          it { is_expected.to eq(%Q{
            |.some_ns(apikey: nil)
            |  It's namespace, you know?..
            |  It is ok.
            |
            |  @param apikey [#to_s]
            |
            |  Namespaces:
            |
            |  .child_ns()
            |
            |  Endpoints:
            |
            |  .some_ep(foo: nil)
            |    @param foo [#to_s]
          }.unindent)}
        end
      end
    end
  end
end
