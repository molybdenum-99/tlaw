module TLAW
  module DSL
    class BaseWrapper
      def initialize(object)
        @object = object
      end

      def define(&block)
        instance_eval(&block)
      end

      def description(text)
        @object.description = text
          .gsub(/^[ \t]+/, '')         # remove spaces at a beginning of string
          .gsub(/\A\n|\n\s*\Z/, '') # remove empty strings before and after
      end

      def param(name, type = nil, **opts)
        @object.param_set.add(name, **opts.merge(type: type))
      end
    end

    class EndpointWrapper < BaseWrapper
      def post_process(key = nil, &block)
        @object.response_processor.add_post_processor(key, &block)
      end

      def post_process_each(key, subkey = nil, &block)
        @object.response_processor.add_item_post_processor(key, subkey, &block)
      end
    end

    class NamespaceWrapper < BaseWrapper
      def endpoint(name, path: nil, **opts, &block)
        define_child(name, path, Endpoint, EndpointWrapper, :add_endpoint, **opts, &block)
      end

      def namespace(name, path: nil, **opts, &block)
        define_child(name, path, Namespace, NamespaceWrapper, :add_namespace, **opts, &block)
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

      private

      def define_child(name, path, child_class, wrapper_class, adder, **opts, &block)
        Class.new(child_class).tap do |c|
          c.path = path || "/#{name}"
          c.symbol = name

          Addressable::Template.new(c.path).keys.each do |key|
            c.param_set.add key.to_sym, keyword_argument: false
          end

          wrapper_class.new(c).define(&block) if block
          @object.send(adder, c)
        end
      end
    end

    class APIWrapper < NamespaceWrapper
      def base(url)
        @object.base_url=  url
      end
    end
  end
end
