require_relative 'base_builder'

module TLAW
  module DSL
    class EndpointBuilder < BaseBuilder
      def finalize
        Class.new(Endpoint).tap { |cls| cls.setup!(definition) }
      end
    end
  end
end
