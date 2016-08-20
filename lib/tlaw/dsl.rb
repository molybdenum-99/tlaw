module TLAW
  module DSL
    module ParamDefiner
      def param(name, type = nil, **opts)
        @object.__send__(:add_param, name, **opts.merge(type: type))
      end
    end

    module EndpointDefiner
      def endpoint(name, path: nil, **opts, &block)
        Class.new(Endpoint).tap do |ep|
          ep.api = @object
          ep.url = @object.base_url + (path || "/#{name}")
          ep.endpoint_name = name
          EndpointWrapper.new(ep).define(&block)
          @object.params.each do |name, param|
            ep.add_param name, **param.to_h.merge(common: true)
          end
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
          ns.base_url = @object.base_url + (path || "/#{name}")
          ns.namespace_name = name
          @object.params.each do |name, param|
            ns.add_param name, **param.to_h.merge(common: true)
          end
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
