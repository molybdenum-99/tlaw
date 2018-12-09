require 'tlaw/dsl/endpoint_builder'

RSpec.describe TLAW::DSL::EndpointBuilder do
  describe '#finalize' do
    let(:builder) {
      described_class.new(name: :foo, path: '/bar/{baz}') do
        description 'Good description'
        param :foo, Integer
        param :quux
      end
    }
    subject { builder.finalize }

    it { is_expected.to be < TLAW::Endpoint }
    its(:definition) {
      is_expected.to eq(
        name: :foo,
        path: '/bar/{baz}',
        description: 'Good description',
        params: {
          baz: {keyword: false},
          foo: {type: Integer},
          quux: {}
        }
      )
    }
  end
end
