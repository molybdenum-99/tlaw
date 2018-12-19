# frozen_string_literal: true

require_relative 'base_builder'
require_relative 'endpoint_builder'

module TLAW
  module DSL
    # @private
    class NamespaceBuilder < BaseBuilder
      CHILD_CLASSES = {NamespaceBuilder => Namespace, EndpointBuilder => Endpoint}.freeze

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

      def initialize(children: [], **args, &block)
        @children = children.map { |c| [c.symbol, c] }.to_h
        super(**args, &block)
      end

      def definition
        super.merge(children: children.values)
      end

      def endpoint(symbol, path = nil, **opts, &block)
        child(EndpointBuilder, symbol, path, **opts, &block)
      end

      def namespace(symbol, path = nil, **opts, &block)
        child(NamespaceBuilder, symbol, path, **opts, &block)
      end

      def finalize
        Namespace.define(**definition).tap(&method(:define_children_methods))
      end

      private

      def child(builder_class, symbol, path, **opts, &block)
        target_class = CHILD_CLASSES.fetch(builder_class)
        existing = children[symbol]
          &.tap { |c|
            c < target_class or fail ArgumentError, "#{symbol} already defined as #{c.ansestors.first}"
          }
          &.definition || {}

        builder_class.new(
          symbol: symbol,
          path: path,
          context: self,
          **opts,
          **existing,
          &block
        ).finalize.tap { |child| children[symbol] = child }
      end

      def define_children_methods(namespace)
        children.each_value do |child|
          namespace.module_eval(child_method_code(child))
        end
      end

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
