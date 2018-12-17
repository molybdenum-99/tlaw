require 'tlaw/dsl/base_builder'

RSpec.describe TLAW::DSL::BaseBuilder do
  describe '#initialize' do
    subject(:call) { ->(*params) { described_class.new(*params).definition }  }

    its_call(symbol: :foo) { is_expected.to ret include(symbol: :foo, path: '/foo') }
    its_call(symbol: :foo, path: '/bar') { is_expected.to ret include(symbol: :foo, path: '/bar') }

    context 'params auto-parsing' do
      subject { described_class.new(symbol: :foo, path: '/bar/{baz}?{quux}') }

      its(:params) {
        are_expected.to eq(
          baz: {keyword: false},
          quux: {keyword: false}
        )
      }
    end
  end

  let(:builder) { described_class.new(symbol: :foo, **opts) }
  let(:opts) { {} }

  describe '#description' do
    subject { builder.method(:description) }
    its_call("Very detailed and thoroughful\ndescription.") {
      is_expected.to change(builder, :definition).to include(description: "Very detailed and thoroughful\ndescription.")
    }
  end

  describe '#docs' do
    subject { builder.method(:docs) }
    its_call('https://google.com') {
      is_expected.to change(builder, :definition).to include(docs_link: 'https://google.com')
    }
  end

  describe '#param' do
    subject { builder.method(:param) }

    its_call(:x, Integer) {
      is_expected.to change(builder, :params).to include(x: {type: Integer})
    }

    context 'merging with params from path (preserve order and options)' do
      let(:opts) { {path: '/bar/{baz}'} }

      its_call(:baz, Integer) {
        is_expected.to change(builder, :params).to include(baz: {keyword: false, type: Integer})
      }
      its_call(:x, Integer) {
        is_expected.to change{ builder.params.keys }.to %i[baz x]
      }
    end
  end

  # TODO: params => param_defs test

  describe '#post_process'
  describe '#post_process_items'
end