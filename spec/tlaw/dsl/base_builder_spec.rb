require 'tlaw/dsl/base_builder'

RSpec.describe TLAW::DSL::BaseBuilder do
  describe '#initialize' do
    subject(:call) { ->(*params) { described_class.new(*params).definition }  }

    its_call(name: :foo) { is_expected.to ret include(name: :foo, path: '/foo') }
    its_call(name: :foo, path: '/bar') { is_expected.to ret include(name: :foo, path: '/bar') }

    context 'params auto-parsing' do
      subject { call.(name: :foo, path: '/bar/{baz}?{quux}') }

      its([:params]) {
        are_expected.to eq(
          baz: {keyword: false},
          quux: {keyword: false}
        )
      }
    end
  end

  let(:builder) { described_class.new(name: :foo, **opts) }
  let(:opts) { {} }

  describe '#description' do
    subject { builder.method(:description) }
    its_call(%Q{
      Very detailed and thoroughful
      description.
    }) {
      is_expected.to change(builder, :definition).to include(description: "Very detailed and thoroughful\ndescription.")
    }
  end

  describe '#docs' do
    subject { builder.method(:docs) }
    its_call('https://google.com') {
      is_expected.to change(builder, :definition).to include(docs: 'https://google.com')
    }
  end

  describe '#param' do
    subject { builder.method(:param) }
    its_call(:x, Integer) {
      is_expected.to change { builder.definition[:params] }.to include(x: {type: Integer})
    }

    context 'merging with params from path (preserve order and options)' do
      let(:opts) { {path: '/bar/{baz}'} }

      its_call(:baz, Integer) {
        is_expected.to change { builder.definition[:params] }.to include(baz: {keyword: false, type: Integer})
      }
      its_call(:x, Integer) {
        is_expected.to change { builder.definition[:params].keys }.to %i[baz x]
      }
    end
  end

  describe '#post_process'
  describe '#post_process_items'
end