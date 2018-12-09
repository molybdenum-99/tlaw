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
        super(name: nil, &block)
      end

      def finalize
        # TODO: What if result is dynamic, without associated const name?
        super.tap { |res| constantize_children(res) }
      end

      private

      def result_class
        @api_class
      end

      def constantize_children(namespace)
        return unless namespace.name.match?(/^[A-Z]/) && namespace.respond_to?(:children)

        namespace.children.each do |child|
          class_name = CLASS_NAMES[child.symbol] || Util.camelize(child.symbol.to_s)
          namespace.const_set(class_name, child)
          constantize_children(child)
        end
      end
    end
  end
end