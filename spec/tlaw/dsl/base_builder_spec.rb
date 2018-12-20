# frozen_string_literal: true

require 'tlaw/dsl/base_builder'

RSpec.describe TLAW::DSL::BaseBuilder do
  let(:opts) { {} }
  let(:builder) { described_class.new(symbol: :foo, **opts) }

  describe '#initialize' do
    subject(:call) { ->(*params) { described_class.new(*params).definition } }

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

  describe '#description' do
    subject { builder.method(:description) }

    its_call("Very detailed and thoroughful\ndescription.") {
      is_expected.to change(builder, :definition).to include(description: "Very detailed and thoroughful\ndescription.")
    }
    its_call(%{
      The description with some
        weird spacing.
      ...and other stuff.
    }) {
      is_expected.to change(builder, :definition).to include(description: "The description with some\nweird spacing.\n...and other stuff.")
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
    its_call(:x, desc: " Foo\n  bar.") {
      is_expected.to change(builder, :params).to include(x: {description: "Foo\nbar."})
    }
    its_call(:x, description: " Foo\n  bar.") {
      is_expected.to change(builder, :params).to include(x: {description: "Foo\nbar."})
    }

    context 'merging with params from path (preserve order and options)' do
      let(:opts) { {path: '/bar/{baz}'} }

      its_call(:baz, Integer) {
        is_expected.to change(builder, :params).to include(baz: {keyword: false, type: Integer})
      }
      its_call(:x, Integer) {
        is_expected.to change { builder.params.keys }.to %i[baz x]
      }
    end
  end

  # TODO: params => param_defs test

  describe '#shared_def' do
    before {
      builder.shared_def(:foo) {}
    }
    subject { builder }

    its(:shared_definitions) { are_expected.to include(:foo) }
  end

  describe '#use_def' do
    before {
      builder.shared_def(:foo) {
        param :bar
      }
    }
    subject { builder.method(:use_def) }

    its_call(:foo) {
      is_expected.to change(builder, :params).to include(:bar)
    }
    its_call(:bar) {
      is_expected.to raise_error ArgumentError, ':bar is not a shared definition'
    }
  end

  describe '#post_process'
  describe '#post_process_items'
end
