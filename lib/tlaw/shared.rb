module TLAW
  module Shared
    module ParamHolder
      def add_param(name, **opts)
        params[name] = Param.new(name, **opts)
      end

      def params
        @params ||= {}
      end
    end

    module NamespaceHolder
      def add_namespace(namespace)
        name = namespace.namespace_name

        # TODO: validate if it is classifiable
        const_set(Util::camelize(name), namespace)
        namespaces[name] = namespace

        define_method(name) { @namespaces[name] }
      end

      def namespaces
        @namespaces ||= {}
      end
    end

    module EndpointHolder
      def add_endpoint(endpoint)
        name = endpoint.endpoint_name

        # TODO: validate if it is classifiable
        const_set(Util::camelize(name), endpoint)
        endpoints[name] = endpoint

        define_method(name) { |*arg, **param|
          @endpoints[name].call(*arg, **@initial_param.merge(param))
        }
      end

      def endpoints
        @endpoints ||= {}
      end
    end
  end
end
