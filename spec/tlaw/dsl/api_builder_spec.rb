# frozen_string_literal: true

require 'tlaw/dsl/api_builder'

RSpec.describe TLAW::DSL::ApiBuilder do
  describe '#finalize' do
    let(:api) { Class.new(TLAW::API) }
    let(:builder) {
      described_class.new(api) do
        base 'http://google.com'

        namespace :foo do
          endpoint :bar do
          end
        end
      end
    }

    subject { builder.finalize }

    its(:base_url) { 'http://google.com' }

    context 'when built for existing class' do
      before do
        stub_const('TheAPI', api)
      end

      its_block {
        is_expected.to define_constant('TheAPI::Foo::Bar')
      }
    end

    context 'when built for dynamic class'
  end
end
