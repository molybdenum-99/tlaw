module TLAW
  class Namespace < APIObject
    class << self
      def base_url=(url)
        @base_url = url

        children.values.each do |child|
          if child.path && !child.base_url
            child.base_url = base_url + child.path
          end
        end
      end

      def namespaces
        children.select { |_k, v| v < Namespace }
      end

      def endpoints
        children.select { |_k, v| v < Endpoint }
      end

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

      def inspect_docs
        inspect_namespaces + inspect_endpoints + ' docs: .describe>'
      end

      def inspect_namespaces
        return '' if namespaces.empty?
        " namespaces: #{namespaces.keys.join(', ')};"
      end

      def inspect_endpoints
        return '' if endpoints.empty?
        " endpoints: #{endpoints.keys.join(', ')};"
      end

      def add_child(child)
        name = child.symbol

        # TODO:
        # * validate if it is classifiable
        # * provide reasonable defaults for non-classifiable (like :[])
        # * provide additional option for non-default class name
        const_set(Util.camelize(name), child)
        children[name] = child
        child.param_set.parent = param_set
        if child.path && !child.base_url && base_url
          child.base_url = base_url + child.path
        end
        child.define_method_on(self)
      end

      def children
        @children ||= {}
      end

      def describe
        super + namespaces_description + endpoints_description
      end

      def to_tree
        Util::Description.new(
          ".#{to_method_definition}\n" +
          children.values.partition { |c| c.is_a?(Namespace) }.flatten.
            map(&:to_tree).map { |d| d.indent('  ') }.join("\n") +
          "\n"
        )
      end

      private

      def namespaces_description
        return '' if namespaces.empty?

        "\n\n  Namespaces:\n\n" +
          namespaces.values.map(&:describe_short)
                    .map { |ns| ns.indent('  ') }.join("\n\n")
      end

      def endpoints_description
        return '' if endpoints.empty?

        "\n\n  Endpoints:\n\n" +
          endpoints.values.map(&:describe_short)
                   .map { |ed| ed.indent('  ') }.join("\n\n")
      end

    end

    def namespaces
      self.class.namespaces
    end

    def endpoints
      self.class.endpoints
    end

    def inspect
      "#<#{self.class.symbol}(#{param_set.to_hash_code(@parent_params)})" +
        self.class.inspect_docs
    end

    def describe
      Util::Description.new(
        self.class.describe +
        namespaces_description +
        endpoints_description
      )
    end

    def describe_short
      self.class.describe_short
    end

    private

    def param_set
      self.class.param_set
    end

    def child(symbol, expected_class, **params)
      self
        .class.children[symbol]
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
