module TLAW
  class API
    attr_reader :endpoints, :namespaces, :initial_param

    def initialize(**param)
      @initial_param = param
      @endpoints = self.class.endpoints.map { |name, klass| [name, klass.new(self)] }.to_h
      @namespaces = self.class.namespaces.map { |name, klass| [name, klass.new(self)] }.to_h
    end

    def call(path)
      open(self.class.base_url + '/' + path).read
        .derp { |response| JSON.parse(response) }
        .derp(&Util.method(:flatten_hashes))
    end

    private

    class << self
      attr_accessor :base_url

      def define(&block)
        DSL::APIWrapper.new(self).define(&block)
      end

      def add_param(**opts)
      end

      def add_endpoint(endpoint)
        name = endpoint.endpoint_name

        # TODO: validate a) if it already exists b) if it is classifiable
        const_set(Util::camelize(name), endpoint)
        endpoints[name] = endpoint

        define_method(name) { |*arg, **param|
          @endpoints[name].call(*arg, **@initial_param.merge(param))
        }
      end

      def add_namespace(namespace)
        name = namespace.namespace_name

        # TODO: validate a) if it already exists b) if it is classifiable
        const_set(Util::camelize(name), namespace)
        namespaces[name] = namespace

        define_method(name) { @namespaces[name] }
      end

      def endpoints
        @endpoints ||= {}
      end

      def namespaces
        @namespaces ||= {}
      end
    end
  end
end
