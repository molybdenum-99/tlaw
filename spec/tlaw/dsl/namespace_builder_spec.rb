require 'tlaw/dsl/namespace_builder'

RSpec.describe TLAW::DSL::NamespaceBuilder do
  let(:builder) { described_class.new(name: :foo) }

  describe '#endpoint' do
    subject { builder.endpoint(:foo, '/bar') { param :bar } }

    its_block {
      is_expected.to change(builder, :children)
        .to contain_exactly(
          have_attributes(symbol: :foo).and be < (TLAW::Endpoint)
        )
    }
    its_block {
      is_expected
        .to send_message(TLAW::DSL::EndpointBuilder, :new)
        .with(name: :foo, path: '/bar', parent: be.<(TLAW::Namespace)).calling_original
    }
  end

  describe '#namespace' do
    subject { builder.namespace(:foo, '/bar') { param :bar } }

    its_block {
      is_expected.to change(builder, :children)
        .to contain_exactly(
          have_attributes(symbol: :foo).and be < (TLAW::Namespace)
        )
    }
    its_block {
      is_expected
        .to send_message(TLAW::DSL::NamespaceBuilder, :new)
        .with(name: :foo, path: '/bar', parent: be.<(TLAW::Namespace)).calling_original
    }
  end

  describe '#finalize' do
    let(:builder) {
      described_class.new(name: :foo, path: '/bar/{baz}') do
        description 'Good description'
        param :foo, Integer
        param :quux

        endpoint :blah do
          param :nice
        end
      end
    }
    subject { builder.finalize }

    it { is_expected.to be < TLAW::Namespace }
    its(:definition) {
      is_expected.to match(
        name: :foo,
        path: '/bar/{baz}',
        description: 'Good description',
        params: {
          baz: {keyword: false},
          foo: {type: Integer},
          quux: {}
        },
        children: contain_exactly(be.<(TLAW::Endpoint))
      )
    }

    its(:instance_methods) { are_expected.to include(:blah) }
  end
end
