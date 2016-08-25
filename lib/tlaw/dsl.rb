module TLAW
  module DSL
    module ParamDefiner
      def param(name, type = nil, **opts)
        @object.param_set.add(name, **opts.merge(type: type))
      end
    end

    module EndpointDefiner
      def endpoint(name, path: nil, **opts, &block)
        Class.new(Endpoint).tap do |ep|
          ep.api = @object
          url = @object.base_url + (path || "/#{name}")
          ep.url = url
          ep.endpoint_name = name
          Addressable::Template.new(url).keys.each do |key|
            ep.add_param key.to_sym, keyword_argument: false
          end

          EndpointWrapper.new(ep).define(&block) if block

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

      def post_process(key = nil, &block)
        @object.endpoints.values.each do |e|
          e.response_processor.add_post_processor(key, &block)
        end
      end

      def post_process_each(key, subkey = nil, &block)
        @object.endpoints.values.each do |e|
          e.response_processor.add_item_post_processor(key, subkey, &block)
        end
      end
    end

    class EndpointWrapper < BaseWrapper
      include ParamDefiner

      def post_process(key = nil, &block)
        @object.response_processor.add_post_processor(key, &block)
      end

      def post_process_each(key, subkey = nil, &block)
        @object.response_processor.add_item_post_processor(key, subkey, &block)
      end
    end

    class NamespaceWrapper < BaseWrapper
      include ParamDefiner
      include EndpointDefiner

      def post_process(key = nil, &block)
        @object.endpoints.values.each do |e|
          e.response_processor.add_post_processor(key, &block)
        end
      end

      def post_process_each(key, subkey = nil, &block)
        @object.endpoints.values.each do |e|
          e.response_processor.add_item_post_processor(key, subkey, &block)
        end
      end
    end
  end
end
