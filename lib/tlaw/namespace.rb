# frozen_string_literal: true

module TLAW
  # Namespace is a grouping tool for API endpoints.
  #
  # Assuming we have this API definition:
  #
  # ```ruby
  # class OpenWeatherMap < TLAW::API
  #   define do
  #     base 'http://api.openweathermap.org/data/2.5'
  #
  #     namespace :current, '/weather' do
  #       endpoint :city, '?q={city}{,country_code}'
  #     end
  #   end
  # end
  # ```
  #
  # We can now use it this way:
  #
  # ```ruby
  # api = OpenWeatherMap.new
  # api.namespaces
  # # => [OpenWeatherMap::Current(call-sequence: current; endpoints: city; docs: .describe)]
  # api.current
  # # => #<OpenWeatherMap::Current(); endpoints: city; docs: .describe>
  # #    OpenWeatherMap::Current is dynamically generated class, descendant from Namespace,
  # #    it is inspectable and usable for future calls
  #
  # api.current.describe
  # # current
  # #
  # #   Endpoints:
  # #
  # #   .city(city=nil, country_code=nil)
  #
  # api.current.city('Kharkiv', 'UA')
  # # => real API call at /weather?q=Kharkiv,UA
  # ```
  #
  # Namespaces are useful for logical endpoint grouping and allow providing additional params to
  # them. When params are defined for namespace by DSL, the call could look like this:
  #
  # ```ruby
  # worldbank.countries('uk').population(2016)
  # #         ^^^^^^^^^^^^^^            ^
  # # namespace :countries have         |
  # # defined country_code parameter    |
  # #                               all namespace and endpoint params would be passed to endpoint call,
  # #                               so real API call would probably look like ...?country=uk&year=2016
  # ```
  #
  # See {DSL} for more details on namespaces, endpoints and params definitions.
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
      # @yield [Namespace or Endpoint]
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

      # Returns the namespace's nested namespaces of the requested name.
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
