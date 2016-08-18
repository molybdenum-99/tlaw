module TLAW
  module DSL
    module ParamDefiner
      def param(name, type, **opts)
        @object.__send__(:add_param, **opts.merge(name: name, type: type))
      end
    end

    module EndpointDefiner
      def endpoint(name, path: nil, **opts, &block)
        Class.new(Endpoint).tap do |ep|
          ep.api = @object
          ep.path = path || "/#{name}"
          ep.endpoint_name = name
          EndpointWrapper.new(ep).define(&block)
          @object.__send__(:add_endpoint, ep)
        end
      end
    end

    class BaseWrapper
      def initialize(object)
        @object = object
      end

      def define(&block)
        instance_eval(&block)
      end
    end

    class APIWrapper < BaseWrapper
      def base(url)
        @object.__send__(:base_url=, url)
      end

      include ParamDefiner
      include EndpointDefiner

      def namespace(name, path: nil, **opts, &block)
        Class.new(Namespace).tap do |ns|
          ns.api = @object
          ns.path = path || "/#{name}"
          ns.namespace_name = name
          NamespaceWrapper.new(ns).define(&block)
          @object.__send__(:add_namespace, ns)
        end
      end
    end

    class EndpointWrapper < BaseWrapper
      include ParamDefiner
    end

    class NamespaceWrapper < BaseWrapper
      include ParamDefiner
      include EndpointDefiner
    end
  end
end
