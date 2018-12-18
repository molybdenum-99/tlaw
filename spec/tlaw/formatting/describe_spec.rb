# frozen_string_literal: true

require 'tlaw/formatting/describe'

RSpec.describe TLAW::Formatting::Describe do
  describe '.endpoint_class' do
    let(:ep) {
      TLAW::DSL::EndpointBuilder.new(symbol: :foo, path: '/foo') {
        desc 'The description'

        param :a, Integer, keyword: false, required: true, desc: 'It is a param!'
        param :b, enum: %w[a b], required: true, desc: 'It is another one'
      }.finalize
    }

    subject { described_class.endpoint_class(ep) }

    it {
      is_expected.to eq <<~DESC.rstrip
        foo(a, b:)

          The description

          @param a [Integer] It is a param!
          @param b It is another one
            Possible values: "a", "b"
      DESC
    }
  end

  describe '.namespace_class' do
    let(:ns) {
      TLAW::DSL::NamespaceBuilder.new(symbol: :foo, path: '/foo') {
        desc 'The description'

        param :a, Integer, keyword: false, required: true, desc: 'It is a param!'
        param :b, enum: %w[a b], required: true, desc: 'It is another one'

        namespace :nested do
          desc 'Nested NS'
          param :c
        end

        endpoint :ep do
          desc 'Nested EP'
          param :d
        end
      }.finalize
    }

    subject { described_class.namespace_class(ns) }

    it {
      is_expected.to eq <<~DESC.rstrip
        foo(a, b:)

          The description

          @param a [Integer] It is a param!
          @param b It is another one
            Possible values: "a", "b"
      DESC
    }
  end
end
