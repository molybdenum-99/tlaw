require_relative 'base_builder'
require_relative 'endpoint_builder'

module TLAW
  module DSL
    class NamespaceBuilder < BaseBuilder
      attr_reader :children

      ENDPOINT_METHOD = <<~CODE
        def %{call_sequence}
          child(:%{symbol}, Endpoint, %{params}).call
        end
      CODE

      NAMESPACE_METHOD = <<~CODE
        def %{call_sequence}
          child(:%{symbol}, Namespace, %{params})
        end
      CODE

      METHODS = {Endpoint => ENDPOINT_METHOD, Namespace => NAMESPACE_METHOD}.freeze

      def initialize(*)
        @children = []
        super
      end

      def definition
        super.merge(children: children)
      end

      def endpoint(symbol, path = nil, **opts, &block)
        EndpointBuilder.new(
          symbol: symbol,
          path: path,
          **opts,
          &block
        ).finalize.tap(&children.method(:push))
      end

      def namespace(symbol, path = nil, **opts, &block)
        NamespaceBuilder.new(
          symbol: symbol,
          path: path,
          **opts,
          &block
        ).finalize.tap(&children.method(:push))
      end

      def finalize
        Namespace.define(**definition).tap do |cls|
          children.each do |child|
            cls.module_eval(child_method_code(child))
          end
        end
      end

      private

      def child_method_code(child)
        params = child.param_defs.map { |par| "#{par.name}: #{par.name}" }.join(', ')
        METHODS.fetch(child.ancestors[1]) % {
          call_sequence: Formatting.call_sequence(child),
          symbol: child.symbol,
          params: params
        }
      end
    end
  end
end
