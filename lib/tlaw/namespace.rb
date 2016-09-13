module TLAW
  class Namespace < APIObject
    class << self
      # @private
      def base_url=(url)
        @base_url = url

        children.values.each do |c|
          c.base_url = base_url + c.path if c.path && !c.base_url
        end
      end

      def namespaces
        children.select { |_k, v| v < Namespace }
      end

      def endpoints
        children.select { |_k, v| v < Endpoint }
      end

      # @private
      def to_code
        "def #{to_method_definition}\n" \
        "  child(:#{symbol}, Namespace, {#{param_set.to_hash_code}})\n" \
        'end'
      end

      def inspect
        "#<#{name || '(unnamed namespace class)'}: " \
        "call-sequence: #{symbol}(#{param_set.to_code});" +
          inspect_docs
      end

      # @private
      def inspect_docs
        inspect_namespaces + inspect_endpoints + ' docs: .describe>'
      end

      # @private
      def add_child(child)
        const_set(child.class_name, child)
        children[child.symbol] = child

        child.base_url = base_url + child.path if !child.base_url && base_url

        child.define_method_on(self)
      end

      def children
        @children ||= {}
      end

      def describe(definition = nil)
        super + describe_children
      end

      private

      def inspect_namespaces
        return '' if namespaces.empty?
        " namespaces: #{namespaces.keys.join(', ')};"
      end

      def inspect_endpoints
        return '' if endpoints.empty?
        " endpoints: #{endpoints.keys.join(', ')};"
      end

      def describe_children
        describe_namespaces + describe_endpoints
      end

      def describe_namespaces
        return '' if namespaces.empty?

        "\n\n  Namespaces:\n\n" + children_description(namespaces)
      end

      def describe_endpoints
        return '' if endpoints.empty?

        "\n\n  Endpoints:\n\n" + children_description(endpoints)
      end

      def children_description(children)
        children.values.map(&:describe_short)
                .map { |cd| cd.indent('  ') }.join("\n\n")
      end
    end

    def_delegators :object_class,
                   :symbol,
                   :children, :namespaces, :endpoints,
                   :param_set, :describe_short

    def inspect
      "#<#{symbol}(#{param_set.to_hash_code(@parent_params)})" +
        self.class.inspect_docs
    end

    def describe
      self.class
          .describe("#{symbol}(#{param_set.to_hash_code(@parent_params)})")
    end

    private

    def child(symbol, expected_class, **params)
      children[symbol]
        .tap { |child_class|
          child_class && child_class < expected_class or
            fail ArgumentError,
                 "Unregistered #{expected_class.name.downcase}: #{symbol}"
        }.derp { |child_class|
          child_class.new(@parent_params.merge(params))
        }
    end
  end
end
