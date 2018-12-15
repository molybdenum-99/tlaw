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

      def define(children: [], **args)
        super(**args).tap do |cls|
          cls.children = children.dup.each { |c| c.parent = cls }
        end
      end

      # @private
      def base_url=(url)
        @base_url = url

        children.each do |c|
          c.base_url = base_url + c.path if c.path && !c.base_url
        end
      end

      RESTRICTION = {
        endpoints: Endpoint,
        namespaces: Namespace,
        nil => APIPath
      }.freeze

      def traverse(restrict_to = nil, &block)
        return to_enum(:traverse, restrict_to) unless block_given?
        klass = RESTRICTION.fetch(restrict_to)
        children.each do |child|
          yield child if child < klass
          child.traverse(restrict_to, &block) if child.respond_to?(:traverse)
        end
        self
      end

      # Returns the namespace's child of the requested name.
      #
      # @return [Array<Endpoint>]
      def child(name, restrict_to: nil)
        child_index.fetch(name).tap do |ep|
          fail ArgumentError, "#{name} is not an #{restrict_to}" unless ep < (restrict_to || Object)
        end
      end

      # Lists all current namespace's nested namespaces.
      #
      # @return [Namespace, ...]
      def namespaces
        children.grep(Namespace.singleton_class)
      end

      # Returns the namespace's endpoint of the requested name.
      #
      # @param name
      # @return [Array<Endpoint>]
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
      # @param name
      # @return [Array<Endpoint>]
      def endpoint(name)
        child(name, restrict_to: Endpoint)
      end

      # def inspect
      #   Inspect.inspect_namespace(self)
      # end

      # @private
      def children
        child_index.values
      end

      # @private
      def child_index
        @child_index ||= {}
      end

      # Detailed namespace documentation.
      #
      # See {APIPath.describe} for explanations.
      #
      # @return [Util::Description]
      def describe
        Inspect.describe_namespace(self)
      end

      protected

      def children=(children)
        children.each do |child|
          child_index[child.symbol] = child
        end
      end
    end

    def_delegators :self_class,
                   :symbol, :name_to_call,
                   :child_index, :children, :namespaces, :endpoint, :endpoints,
                   :param_set, :describe_short

    # def inspect
    #   Inspect.inspect_namespace(self.class, @parent_params)
    # end

    # def describe
    #   Inspect.describe_namespace(self.class, @parent_params)
    # end

    private

    def child(sym, expected_class, **params)
      child_index[sym]
        .tap { |child_class| validate_class(sym, child_class, expected_class) }
        .new(self, **params)
    end

    def validate_class(sym, child_class, expected_class)
      return if child_class < expected_class
      fail ArgumentError,
           "Unregistered #{expected_class.name.split('::').last.downcase}: #{sym}"
    end
  end
end
