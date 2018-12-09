require_relative 'base_builder'
require_relative 'endpoint_builder'

module TLAW
  module DSL
    class NamespaceBuilder < BaseBuilder
      attr_reader :children

      ENDPOINT_METHOD = <<~CODE
        def %{call_sequence}
          child(:%{symbol}, Endpoint).call(%{params})
        end
      CODE

      NAMESPACE_METHOD = <<~CODE
        def %{call_sequence}
          child(:%{symbol}, Namespace, %{params})
        end'
      CODE

      METHODS = {Endpoint => ENDPOINT_METHOD, Namespace => NAMESPACE_METHOD}.freeze

      def initialize(*)
        @children = []
        super
      end

      def definition
        super.merge(children: children)
      end

      def endpoint(name, path = nil, **opts, &block)
        children << EndpointBuilder.new(name: name, path: path, parent: result_class, **opts, &block).finalize
      end

      def namespace(name, path = nil, **opts, &block)
        children << NamespaceBuilder.new(name: name, path: path, parent: result_class, **opts, &block).finalize
      end

      def finalize
        result_class.tap do |cls|
          cls.setup!(definition)
          children.each do |child| define_child_method(cls, child) end
        end
      end

      private

      def result_class
        @result_class ||= Class.new(Namespace)
      end

      def define_child_method(host, child)
        code = METHODS.fetch(child.ancestors[1]) % {
          call_sequence: child.call_sequence,
          symbol: child.symbol,
          params: child.param_set.to_hash_code
        }

        host.module_eval(code)
      end
    end
  end
end
