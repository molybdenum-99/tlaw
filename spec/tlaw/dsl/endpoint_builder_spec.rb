# frozen_string_literal: true

require 'tlaw/dsl/endpoint_builder'

RSpec.describe TLAW::DSL::EndpointBuilder do
  describe '#finalize' do
    let(:builder) {
      described_class.new(symbol: :foo, path: '/bar/{baz}') do
        description 'Good description'
        param :foo, Integer
        param :quux
      end
    }

    subject { builder.finalize }

    it { is_expected.to be < TLAW::Endpoint }
    it {
      is_expected.to have_attributes(
        symbol: :foo,
        path: '/bar/{baz}',
        description: 'Good description'
      )
    }
    its(:param_defs) {
      is_expected.to contain_exactly(
        have_attributes(name: :baz, keyword?: false),
        have_attributes(name: :foo, keyword?: true, type: TLAW::Param::ClassType.new(Integer)),
        have_attributes(name: :quux, type: TLAW::Param::Type.default_type)
      )
    }
  end
end
