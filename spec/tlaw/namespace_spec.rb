module TLAW
  describe Namespace do
    context 'class' do
      context 'definition' do
        subject(:namespace) {
          Class.new(described_class).tap { |c|
            c.base_url = 'https://example.com/ns'
          }
        }

        its(:param_set) { is_expected.to be_a ParamSet }

        describe '.add_child' do
          let(:child) {
            Class.new(APIPath).tap { |c|
              c.symbol = :some_endpoint
              c.path = '/ep'
            }
          }

          before {
            expect(child).to receive(:define_method_on).with(namespace)
            namespace.add_child(child)
          }

          its(:children) { is_expected.to include(some_endpoint: child) }

          context 'updates child' do
            subject { child }

            its(:base_url) { is_expected.to eq 'https://example.com/ns/ep' }
          end
        end
      end

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
          c.add_child endpoint_class
          c.add_child child_class
          c.param_set.add :apikey
        }
      }

      context '.to_code' do
        subject { namespace_class.to_code }

        it { is_expected.to eq(%{
          |def some_ns(apikey: nil)
          |  child(:some_ns, Namespace, {apikey: apikey})
          |end
        }.unindent)}
      end

      context '.describe' do
        before {
          namespace_class.description = "It's namespace, you know?..\nIt is ok."
        }

        subject { namespace_class.describe }

        it { is_expected.to eq(%{
          |.some_ns(apikey: nil)
          |  It's namespace, you know?..
          |  It is ok.
          |
          |  @param apikey
          |
          |  Namespaces:
          |
          |  .child_ns()
          |
          |  Endpoints:
          |
          |  .some_ep(foo: nil)
        }.unindent)}
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
          c.add_child endpoint_class
          c.add_child child_class
          c.param_set.add :apikey
        }
      }
      let(:initial_params) { {} }

      subject(:namespace) { namespace_class.new(initial_params) }

      describe '#<endpoint>' do
        let(:endpoint) { instance_double(endpoint_class, call: nil) }

        subject { namespace.some_ep(foo: 'bar') }

        its_call do
          is_expected
            .to send_message(endpoint_class, :new).returning(endpoint)
            .and send_message(endpoint, :call).with(foo: 'bar')
        end

        context 'initial params' do
          let(:initial_params) { {apikey: 'foo'} }

          its_call do
            is_expected
              .to send_message(endpoint_class, :new).with(apikey: 'foo').returning(endpoint)
              .and send_message(endpoint, :call).with(foo: 'bar')
          end
        end
      end

      context 'documentation' do
        before { allow(namespace_class).to receive(:name).and_return('SomeNamespace') }

        describe '.inspect' do
          subject { namespace_class.inspect }

          it { is_expected.to eq '#<SomeNamespace: call-sequence: some_ns(apikey: nil); namespaces: child_ns; endpoints: some_ep; docs: .describe>' }
        end

        describe '#inspect' do
          subject { namespace.inspect }

          it { is_expected.to eq '#<some_ns(apikey: nil) namespaces: child_ns; endpoints: some_ep; docs: .describe>' }
        end

        describe '#describe' do # this describe just describes the describe. Problems, officer?
          let(:initial_params) { {apikey: 'foo'} }

          before {
            namespace_class.description = "It's namespace, you know?..\nIt is ok."
          }
          subject { namespace.describe.to_s }

          it { is_expected.to eq(%{
            |.some_ns(apikey: "foo")
            |  It's namespace, you know?..
            |  It is ok.
            |
            |  @param apikey
            |
            |  Namespaces:
            |
            |  .child_ns()
            |
            |  Endpoints:
            |
            |  .some_ep(foo: nil)
          }.unindent)}
        end
      end
    end
  end
end
