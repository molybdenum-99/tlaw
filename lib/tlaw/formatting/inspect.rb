# frozen_string_literal: true

module TLAW
  module Formatting
    # @private
    module Inspect
      class << self
        def endpoint(object)
          _object(object)
        end

        def namespace(object)
          _object(object, children_list(object.class))
        end

        def endpoint_class(klass)
          _class(klass, 'endpoint')
        end

        def namespace_class(klass)
          _class(klass, 'namespace', children_list(klass))
        end

        private

        def children_list(namespace)
          ns = " namespaces: #{namespace.namespaces.map(&:symbol).join(', ')};" \
            unless namespace.namespaces.empty?
          ep = " endpoints: #{namespace.endpoints.map(&:symbol).join(', ')};" \
            unless namespace.endpoints.empty?

          [ns, ep].compact.join
        end

        def _object(object, addition = '')
          "#<#{object.class.name}(" +
            object.params.map { |name, val| "#{name}: #{val.inspect}" }.join(', ') +
            ');' +
            addition +
            ' docs: .describe>'
        end

        def _class(klass, type, addition = '')
          (klass.name || "(unnamed #{type} class)") +
            "(call-sequence: #{Formatting.call_sequence(klass)};" +
            addition +
            ' docs: .describe)'
        end
      end
    end
  end
end
