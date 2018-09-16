module TLAW
  # Namespace is basically a container for {Endpoint}s. It allows to
  # nest Ruby calls (like `api.namespace1.namespace2.real_call(params)`),
  # optionally providing some parameters while nesting, like
  # `worldbank.countries('uk').population(2016)`.
  #
  # By default, namespaces nesting also means URL nesting (e.g.
  # `base_url/namespace1/namespace2/endpoint`), but that could be altered
  # on namespace definition, see {DSL} module for details.
  #
  # Typically, as with {Endpoint}, you never create namespace instances
  # or subclasses by yourself: you use {DSL} for their definition and
  # then call `.<namespace_name>` method on parent namespace (or API instance):
  #
  # ```ruby
  # class SampleAPI < TLAW::API
  #   # namespace definition:
  #   namespace :my_ns do
  #     endpoint :weather
  #   end
  # end
  #
  # # usage:
  # api = SampleAPI.new
  #
  # api.namespaces[:my_ns] # => class SampleAPI::MyNS, subclass of namespace
  # api.my_ns # => short-living instance of SampleAPI::MyNS
  # api.my_ns.weather # => real call to API
  # ```
  #
  class Namespace < APIPath
    class << self
      # @private
      def base_url=(url)
        @base_url = url

        children.each_value do |c|
          c.base_url = base_url + c.path if c.path && !c.base_url
        end
      end

      # Lists all current namespace's nested namespaces as a hash.
      #
      # @return [Hash{Symbol => Namespace}]
      def namespaces
        children.select { |_k, v| v < Namespace }
      end

      # Lists all current namespace's endpoints as a hash.
      #
      # @return [Hash{Symbol => Endpoint}]
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
        "#{name || '(unnamed namespace class)'}(" \
        "call-sequence: #{name_to_call}(#{param_set.to_code});" +
          inspect_docs + ')'
      end

      # @private
      alias_method :name_to_call, :symbol

      # @private
      def inspect_docs
        inspect_namespaces + inspect_endpoints + ' docs: .describe'
      end

      # @private
      def add_child(child)
        children[child.symbol] = child

        child.base_url = base_url + child.path if !child.base_url && base_url

        child.define_method_on(self)
      end

      # @private
      def children
        @children ||= {}
      end

      # Detailed namespace documentation.
      #
      # See {APIPath.describe} for explanations.
      #
      # @return [Util::Description]
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
        children.values
                .map(&:describe_short)
                .map { |cd| cd.indent('  ') }
                .join("\n\n")
      end
    end

    def_delegators :object_class,
                   :symbol, :name_to_call,
                   :children, :namespaces, :endpoints,
                   :param_set, :describe_short

    def inspect
      "#<#{name_to_call}(#{param_set.to_hash_code(@parent_params)})" +
        self.class.inspect_docs + '>'
    end

    def describe
      self.class.describe("#{symbol}(#{param_set.to_hash_code(@parent_params)})")
    end

    private

    def child(symbol, expected_class, **params)
      children[symbol]
        .tap do |child_class|
          child_class && child_class < expected_class or
            fail ArgumentError,
                 "Unregistered #{expected_class.name.downcase}: #{symbol}"
        end
        .new(@parent_params.merge(params))
    end
  end
end
