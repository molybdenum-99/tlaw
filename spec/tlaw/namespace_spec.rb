module TLAW
  describe Namespace do
    context 'class' do
      let(:endpoint_class) {
        Class.new(Endpoint).tap { |c|
          c.symbol = :some_ep
          c.path = '/some_ep'
          c.param_set.add :foo
        }
      }

      let(:child_endpoint_class) {
        Class.new(Endpoint).tap { |c|
          c.symbol = :child_ep
          c.path = '/child_ep'
        }
      }

      let(:grand_child_class) {
        Class.new(described_class).tap { |c|
          c.symbol = :grand_child_ns
          c.path = '/ns3'
        }
      }

      let(:child_class) {
        Class.new(described_class).tap { |c|
          c.symbol = :child_ns
          c.path = '/ns2'
          c.add_child child_endpoint_class
          c.add_child grand_child_class
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

      context 'definition' do
        subject(:namespace) {
          Class.new(described_class).tap { |c|
            c.base_url = 'https://example.com/ns'
          }
        }

        its(:param_set) { is_expected.to be_a Params::Set }

        describe '.add_child' do
          let(:child) {
            Class.new(APIPath).tap { |c|
              c.symbol = :some_endpoint
              c.path = '/ep'
            }
          }

          before {
            allow(child).to receive(:define_method_on).with(namespace)
            namespace.add_child(child)
          }

          its(:children) { is_expected.to include(some_endpoint: child) }

          context 'updates child' do
            subject { child }

            its(:base_url) { is_expected.to eq 'https://example.com/ns/ep' }
          end
        end
      end

      context '.to_code' do
        subject { namespace_class.to_code }

        it { is_expected.to eq(%{
          |def some_ns(apikey: nil)
          |  child(:some_ns, Namespace, apikey: apikey)
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

      context '.traverse' do
        subject { ->(*args) { namespace_class.traverse(*args).to_a } }

        it { is_expected.to ret [
          endpoint_class,
          child_class,
          child_endpoint_class,
          grand_child_class
        ]
        }

        its_call(:endpoints) { is_expected.to ret [
          endpoint_class,
          child_endpoint_class
        ]
        }

        its_call(:namespaces) { is_expected.to ret [
          child_class,
          grand_child_class
        ]
        }

        its_call(:garbage) { is_expected.to raise_error KeyError }
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

      subject(:namespace) { namespace_class.new(**initial_params) }

      describe '#<endpoint>' do
        let(:endpoint) { instance_double(endpoint_class, call: nil) }

        subject { namespace.some_ep(foo: 'bar') }

        its_block do
          is_expected
            .to send_message(endpoint_class, :new).returning(endpoint)
            .and send_message(endpoint, :call).with(foo: 'bar')
        end

        context 'initial params' do
          let(:initial_params) { {apikey: 'foo'} }

          its_block do
            is_expected
              .to send_message(endpoint_class, :new).with(namespace, apikey: 'foo').returning(endpoint)
              .and send_message(endpoint, :call).with(foo: 'bar')
          end
        end
      end

      describe '#<namespace>' do
        let(:child_instance) { namespace.child_ns }

        subject { child_instance }

        its(:class) { is_expected.to eq child_class }

        its(:parent) { is_expected.to eq namespace }

        its(:parents) { is_expected.to eq [namespace] }
      end

      context 'documentation' do
        before { allow(namespace_class).to receive(:name).and_return('SomeNamespace') }

        describe '.inspect' do
          subject { namespace_class.inspect }

          it { is_expected.to eq 'SomeNamespace(call-sequence: some_ns(apikey: nil); namespaces: child_ns; endpoints: some_ep; docs: .describe)' }
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
