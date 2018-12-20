# frozen_string_literal: true

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
  # api.namespaces # => [SampleAPI::MyNS], subclass of namespace
  # api.namespace(:my_ns) # => SampleAPI::MyNS
  # api.my_ns # => short-living instance of SampleAPI::MyNS
  # api.my_ns.weather # => real call to API
  # ```
  #
  class Namespace < APIPath
    class << self
      # @private
      TRAVERSE_RESTRICTION = {
        endpoints: Endpoint,
        namespaces: Namespace,
        nil => APIPath
      }.freeze

      # Traverses through all of the children (depth-first). Yields them into a block specified,
      # or returns `Enumerator` if no block was passed.
      #
      # @yields [Namespace,Endpoint]
      # @param restrict_to [Symbol] `:endpoints` or `:namespaces` to traverse only children of
      #   specified class; if not passed, traverses all of them.
      # @return [Enumerator, self] Enumerator is returned if no block passed.
      def traverse(restrict_to = nil, &block)
        return to_enum(:traverse, restrict_to) unless block_given?

        klass = TRAVERSE_RESTRICTION.fetch(restrict_to)
        children.each do |child|
          yield child if child < klass
          child.traverse(restrict_to, &block) if child.respond_to?(:traverse)
        end
        self
      end

      # Returns the namespace's child of the requested name.
      #
      # @param name [Symbol]
      # @param restrict_to [Class] `Namespace` or `Endpoint`
      # @return [Array<APIPath>]
      def child(name, restrict_to: APIPath)
        child_index[name]
          .tap { |child| validate_class(name, child, restrict_to) }
      end

      # Lists all current namespace's nested namespaces.
      #
      # @return [Array<Namespace>]
      def namespaces
        children.grep(Namespace.singleton_class)
      end

      # Returns the namespace's nested namespace of the requested name.
      #
      # @param name [Symbol]
      # @return [Namespace]
      def namespace(name)
        child(name, restrict_to: Namespace)
      end

      # Lists all current namespace's endpoints.
      #
      # @return [Array<Endpoint>]
      def endpoints
        children.grep(Endpoint.singleton_class)
      end

      # Returns the namespace's endpoint of the requested name.
      #
      # @param name [Symbol]
      # @return [Endpoint]
      def endpoint(name)
        child(name, restrict_to: Endpoint)
      end

      # @return [String]
      def inspect
        return super unless is_defined? || self < API

        Formatting::Inspect.namespace_class(self)
      end

      # Detailed namespace documentation.
      #
      # See {APIPath.describe} for explanations.
      #
      # @return [Formatting::Description]
      def describe
        return '' unless is_defined?

        Formatting::Describe.namespace_class(self)
      end

      # @private
      def definition
        super.merge(children: children)
      end

      # @private
      def children
        child_index.values
      end

      # @private
      def child_index
        @child_index ||= {}
      end

      protected

      def setup(children: [], **args)
        super(**args)
        self.children = children.dup.each { |c| c.parent = self }
      end

      def children=(children)
        children.each do |child|
          child_index[child.symbol] = child
        end
      end

      private

      def validate_class(sym, child_class, expected_class)
        return if child_class&.<(expected_class)

        kind = expected_class.name.split('::').last.downcase.sub('apipath', 'path')
        fail ArgumentError,
             "Unregistered #{kind}: #{sym}"
      end
    end

    def_delegators :self_class, :symbol,
                   :namespaces, :endpoints,
                   :namespace, :endpoint

    # @return [String]
    def inspect
      Formatting::Inspect.namespace(self)
    end

    # Returns `curl` string to call specified endpoit with specified params from command line.
    #
    # @param endpoint [Symbol] Endpoint's name
    # @param params [Hash] Endpoint's argument
    # @return [String]
    def curl(endpoint, **params)
      child(endpoint, Endpoint, **params).to_curl
    end

    private

    def child(sym, expected_class, **params)
      self.class.child(sym, restrict_to: expected_class).new(self, **params)
    end
  end
end
