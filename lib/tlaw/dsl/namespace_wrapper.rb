require_relative 'base_wrapper'
require_relative 'endpoint_wrapper'
require_relative 'namespace_wrapper'
require_relative '../endpoint'
require_relative '../namespace'

module TLAW
  module DSL
    class NamespaceWrapper < BaseWrapper
      def endpoint(name, path = nil, **opts, &block)
        name = name.to_sym
        update_existing(Endpoint, name, path, **opts, &block) ||
          add_child(Endpoint, name, path: path || "/#{name}", **opts, &block)
      end

      def namespace(name, path = nil, &block)
        name = name.to_sym
        update_existing(Namespace, name, path, &block) ||
          add_child(Namespace, name, path: path || "/#{name}", &block)
      end

      private

      WRAPPERS = {
        Endpoint => EndpointWrapper,
        Namespace => NamespaceWrapper
      }.freeze

      def update_existing(child_class, name, path, **opts, &block)
        existing = @object.child_index[name] or return nil
        existing < child_class or
          fail ArgumentError, "#{name} is already defined as #{child_class == Endpoint ? 'namespace' : 'endpoint'}, you can't redefine it as #{child_class}"

        !path && opts.empty? or
          fail ArgumentError, "#{child_class} is already defined, you can't change its path or options"

        WRAPPERS[child_class].new(existing).define(&block) if block
      end

      def add_child(child_class, name, **opts, &block)
        @object.add_child(
          child_class.inherit(@object, symbol: name, **opts)
          .tap { |c| c.parent = @object }
          .tap(&:params_from_path!)
          .tap { |c|
            WRAPPERS[child_class].new(c).define(&block) if block
          }
        )
      end
    end
  end
end
