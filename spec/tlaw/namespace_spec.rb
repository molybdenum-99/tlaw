# frozen_string_literal: true

RSpec.describe TLAW::Namespace do
  let(:cls) {
    described_class.define(
      symbol: :ns,
      path: '/ns',
      children: [ep, ns]
    ).tap { |c| c.parent = parent_cls }
  }
  let(:parent_cls) { class_double('TLAW::APIPath', url_template: 'http://foo/bar') }
  let(:ns) {
    described_class.define(symbol: :ns1, path: '/ns1', param_defs: [param(:x)])
  }
  let(:ep) {
    TLAW::Endpoint.define(symbol: :ep1, path: '/ep1', param_defs: [param(:x)])
  }

  describe '.define' do
    subject(:cls) {
      described_class.define(
        symbol: :ns,
        path: '/ns',
        param_defs: [param(:a), param(:b)],
        children: [
          TLAW::Endpoint.define(symbol: :ep1, path: '/ep1'),
          described_class.define(symbol: :ns1, path: '/ns1')
        ]
      )
    }

    its(:children) {
      are_expected
        .to match [
          be.<(TLAW::Endpoint).and(have_attributes(symbol: :ep1, parent: cls)),
          be.<(described_class).and(have_attributes(symbol: :ns1, parent: cls))
        ]
    }

    before {
      allow(cls).to receive(:name).and_return('Namespace')
    }

    its(:inspect) {
      is_expected.to eq 'Namespace(call-sequence: ns(a: nil, b: nil); namespaces: ns1; endpoints: ep1; docs: .describe)'
    }
    its(:describe) { is_expected.to be_a String }
  end

  describe '.child' do
    subject { cls.method(:child) }

    its_call(:ep1, restrict_to: TLAW::Endpoint) { is_expected.to ret be < TLAW::Endpoint }
    its_call(:ep1, restrict_to: described_class) {
      is_expected.to raise_error ArgumentError, 'Unregistered namespace: ep1'
    }
    its_call(:ns1, restrict_to: described_class) { is_expected.to ret be < described_class }
    its_call(:ns1) { is_expected.to ret be < described_class }
    its_call(:ns2) {
      is_expected.to raise_error ArgumentError, 'Unregistered path: ns2'
    }
  end

  describe '.endpoint' do
    subject { cls.method(:endpoint) }

    its_call(:ep1) { is_expected.to ret be < TLAW::Endpoint }
    its_call(:ns1) {
      is_expected.to raise_error ArgumentError, 'Unregistered endpoint: ns1'
    }
    its_call(:ns2) {
      is_expected.to raise_error ArgumentError, 'Unregistered endpoint: ns2'
    }
  end

  describe '.namespace' do
    subject { cls.method(:namespace) }

    its_call(:ns1) { is_expected.to ret be < described_class }
    its_call(:ep1) {
      is_expected.to raise_error ArgumentError, 'Unregistered namespace: ep1'
    }
    its_call(:ns2) {
      is_expected.to raise_error ArgumentError, 'Unregistered namespace: ns2'
    }
  end

  describe '.traverse' do
    let(:namespace_class) {
      TLAW::DSL::NamespaceBuilder.new(symbol: :root) do
        endpoint :endpoint
        namespace :child do
          endpoint :child_endpoint
          namespace :grand_child
        end
      end.finalize
    }

    subject { ->(*args) { namespace_class.traverse(*args).to_a } }

    it { is_expected.to ret contain_exactly(
      have_attributes(symbol: :endpoint),
      have_attributes(symbol: :child),
      have_attributes(symbol: :child_endpoint),
      have_attributes(symbol: :grand_child)
    )
    }

    its_call(:endpoints) { is_expected.to ret contain_exactly(
      have_attributes(symbol: :endpoint),
      have_attributes(symbol: :child_endpoint)
    )
    }

    its_call(:namespaces) { is_expected.to ret contain_exactly(
      have_attributes(symbol: :child),
      have_attributes(symbol: :grand_child)
    )
    }

    its_call(:garbage) { is_expected.to raise_error KeyError }
  end

  describe '#child' do
    let(:obj) { cls.new(nil) }

    subject { obj.method(:child) }

    its_call(:ep1, TLAW::Endpoint, x: 1) { is_expected.to ret be_a(ep).and have_attributes(params: {x: 1}) }
    its_call(:ep1, described_class, x: 1) { is_expected.to raise_error ArgumentError, 'Unregistered namespace: ep1' }
    its_call(:ns1, described_class, x: 1) { is_expected.to ret be_a(ns).and have_attributes(params: {x: 1}) }
  end
end

__END__
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

          its(:child_index) { is_expected.to include(some_endpoint: child) }

          its(:children) { is_expected.to include(child) }

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
          |  .child_ns
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
            |  .child_ns
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
