# frozen_string_literal: true

require_relative 'base_builder'

module TLAW
  module DSL
    # @private
    class EndpointBuilder < BaseBuilder
      def definition
        # TODO: Here we'll be more flexible in future, allowing to avoid flatten/datablize
        all_processors = [
          @parser,
          ResponseProcessors.method(:flatten),
          *processors,
          ResponseProcessors.method(:datablize)
        ]

        super.merge(processors: all_processors)
      end

      def finalize
        Endpoint.define(**definition)
      end
    end
  end
end
