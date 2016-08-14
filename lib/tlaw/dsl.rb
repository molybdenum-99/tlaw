module TLAW
  module DSL
    class APIWrapper
      def initialize(api)
        @api = api
      end

      def define(&block)
        instance_eval(&block)
      end

      def base(url)
        @api.__send__(:base_url=, url)
      end

      def param(name, type, **opts)
        @api.__send__(:add_param, **opts.merge(name: name, type: type))
      end

      def endpoint(path, **opts, &block)
        Class.new(Endpoint).tap do |ep|
          ep.api = @api
          ep.path = path
          EndpointWrapper.new(ep).define(&block)
          @api.__send__(:add_endpoint, path, ep)
        end
      end
    end

    class EndpointWrapper
      def initialize(endpoint)
        @endpoint = endpoint
      end

      def define(&block)
        instance_eval(&block)
      end

      def param(name, type, **opts)
        @endpoint.__send__(:add_param, **opts.merge(name: name, type: type))
      end
    end
  end
end
