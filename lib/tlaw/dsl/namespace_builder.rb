require_relative 'base_builder'
require_relative 'endpoint_builder'

module TLAW
  module DSL
    class NamespaceBuilder < BaseBuilder
      attr_reader :children

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
        result_class.tap { |cls| cls.setup!(definition) }
      end

      private

      def result_class
        @result_class ||= Class.new(Namespace)
      end
    end
  end
end
