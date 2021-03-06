# frozen_string_literal: true

require 'tlaw/dsl/namespace_builder'

RSpec.describe TLAW::DSL::NamespaceBuilder do
  let(:builder) { described_class.new(symbol: :foo) }

  describe '#endpoint' do
    subject { builder.endpoint(:foo, '/bar') { param :bar } }

    its_block {
      is_expected.to change(builder, :children)
        .to match(
          foo: have_attributes(symbol: :foo).and(be < TLAW::Endpoint)
        )
    }
    its_block {
      is_expected
        .to send_message(TLAW::DSL::EndpointBuilder, :new)
        .with(symbol: :foo, path: '/bar', context: instance_of(described_class)).calling_original
    }
  end

  describe '#namespace' do
    subject { builder.namespace(:foo, '/bar') { param :bar } }

    its_block {
      is_expected
        .to change(builder, :children)
        .to match(
          foo: have_attributes(symbol: :foo).and(be < TLAW::Namespace)
        )
    }
    its_block {
      is_expected
        .to send_message(described_class, :new)
        .with(symbol: :foo, path: '/bar', context: instance_of(described_class)).calling_original
    }

    context 'with string symbol' do
      subject { builder.namespace('foo') }

      its_block {
        is_expected.to change(builder, :children).to match(foo: have_attributes(symbol: :foo))
      }
    end

    context 'when it is second definition' do
      before {
        builder.namespace(:foo, '/bar') {
          param :bar
          endpoint(:x) { param :y }
        }
        builder.namespace(:foo) {
          desc 'Description.'
          param :baz
          endpoint(:x) { param :y, required: true }
        }
      }

      subject { builder.children.values.first }

      it {
        is_expected
          .to be.<(TLAW::Namespace)
          .and have_attributes(symbol: :foo, path: '/bar', description: 'Description.')
      }
      its(:param_defs) {
        are_expected.to contain_exactly(have_attributes(name: :bar), have_attributes(name: :baz))
      }
      its(:'endpoints.first.param_defs') {
        are_expected.to contain_exactly(have_attributes(name: :y, required?: true))
      }
    end
  end

  describe '#finalize' do
    let(:builder) {
      described_class.new(symbol: :foo, path: '/bar/{baz}') do
        description 'Good description'
        param :foo, Integer
        param :quux

        endpoint :blah do
          param :nice
        end
      end
    }

    subject(:finalize) { builder.finalize }

    it { is_expected.to be < TLAW::Namespace }
    it {
      is_expected.to have_attributes(
        symbol: :foo,
        path: '/bar/{baz}',
        description: 'Good description',
        children: contain_exactly(be.<(TLAW::Endpoint))
      )
    }

    its(:instance_methods) { are_expected.to include(:blah) }
  end

  describe '#child_method_code' do
    subject { builder.send(:child_method_code, child) }

    context 'for endpoint' do
      let(:child) { TLAW::Endpoint.define(symbol: :blah, path: '', param_defs: [param(:nice)]) }

      it {
        is_expected.to eq <<~METHOD
          def blah(nice: nil)
            child(:blah, Endpoint, nice: nice).call
          end
        METHOD
      }
    end

    context 'for namespace' do
      let(:child) {
        TLAW::Namespace.define(
          symbol: :ns2,
          path: '',
          param_defs: [
            param(:p1, required: true, keyword: false),
            param(:p2, required: true)
          ]
        )
      }

      it {
        is_expected.to eq <<~METHOD
          def ns2(p1, p2:)
            child(:ns2, Namespace, p1: p1, p2: p2)
          end
        METHOD
      }
    end
  end
end
