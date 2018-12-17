# frozen_string_literal: true

require_relative 'base_builder'

module TLAW
  module DSL
    class EndpointBuilder < BaseBuilder
      def finalize
        Endpoint.define(**definition)
      end
    end
  end
end
