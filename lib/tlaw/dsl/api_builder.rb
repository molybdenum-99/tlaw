# frozen_string_literal: true

require_relative 'base_builder'
require_relative 'endpoint_builder'
require_relative 'namespace_builder'

module TLAW
  module DSL
    class ApiBuilder < NamespaceBuilder
      # @private
      CLASS_NAMES = {
        :[] => 'Element'
      }.freeze

      def initialize(api_class, &block)
        @api_class = api_class
        @definition = {}
        super(symbol: nil, &block)
      end

      def finalize
        # TODO: What if result is dynamic, without associated const name?
        @api_class.setup(**definition)
        define_children_methods(@api_class)
        constantize_children(@api_class)
      end

      def base(url)
        @definition[:base_url] = url
      end

      private

      def constantize_children(namespace)
        return unless namespace.name&.match?(/^[A-Z]/) && namespace.respond_to?(:children)

        namespace.children.each do |child|
          class_name = CLASS_NAMES.fetch(child.symbol, Util.camelize(child.symbol.to_s))
          namespace.const_set(class_name, child)
          constantize_children(child)
        end
      end
    end
  end
end
