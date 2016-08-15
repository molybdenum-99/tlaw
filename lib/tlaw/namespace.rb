module TLAW
  class Namespace
    attr_reader :endpoints

    def initialize(api)
      @api = api
      @endpoints = self.class.endpoints.map { |name, klass| [name, klass.new(api)] }.to_h
    end

    class << self
      attr_accessor :api
      attr_accessor :path
      attr_accessor :namespace_name

      def add_endpoint(endpoint)
        name = endpoint.endpoint_name

        # TODO: validate a) if it already exists b) if it is classifiable
        const_set(Util::camelize(name), endpoint)
        endpoints[name] = endpoint

        define_method(name) { |*arg, **param|
          @endpoints[name].call(*arg, **@api.initial_param.merge(_namespace: self.class.path).merge(param))
        }
      end

      def endpoints
        @endpoints ||= {}
      end
    end
  end
end
