module TLAW
  module Formatting
    module Inspect
      module_function

      def endpoint(object)
        "#<#{object.class.name}(" +
          object.params.map { |name, val| "#{name}: #{val.inspect}" }.join(', ') +
          '); docs: .describe>'
      end

      def endpoint_class(klass)
        _class(klass, 'endpoint')
      end

      def namespace_class(klass)
        _class(klass, 'namespace') do
          ns = " namespaces: #{klass.namespaces.map(&:symbol).join(', ')};" \
            unless klass.namespaces.empty?
          ep = " endpoints: #{klass.endpoints.map(&:symbol).join(', ')};" \
            unless klass.endpoints.empty?

          [ns, ep].compact.join
        end
      end

      def _class(klass, type, &block)
        (klass.name || "(unnamed #{type} class)") +
          "(call-sequence: #{Formatting.call_sequence(klass)};" +
          (block&.call || '') +
          ' docs: .describe)'
      end
    end
  end
end
