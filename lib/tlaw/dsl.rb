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
        @object.description =
          text
          .gsub(/^[ \t]+/, '')      # remove spaces at a beginning of each line
          .gsub(/\A\n|\n\s*\Z/, '') # remove empty strings before and after
      end

      alias_method :desc, :description

      def param(name, type = nil, **opts)
        @object.param_set.add(name, **opts.merge(type: type))
      end

      def post_process(key = nil, &block)
        @object.response_processor.add_post_processor(key, &block)
      end

      def post_process_replace(&block)
        @object.response_processor.add_replacer(&block)
      end

      class PostProcessProxy
        def initialize(parent_key, parent)
          @parent_key = parent_key
          @parent = parent
        end

        def post_process(key = nil, &block)
          @parent.add_item_post_processor(@parent_key, key, &block)
        end
      end

      def post_process_items(key, &block)
        PostProcessProxy
          .new(key, @object.response_processor)
          .instance_eval(&block)
      end
    end

    class EndpointWrapper < BaseWrapper
    end

    # rubocop:disable Metrics/ParameterLists
    class NamespaceWrapper < BaseWrapper
      def endpoint(name, path: nil, **opts, &block)
        define_child(name, path, Endpoint, EndpointWrapper, **opts, &block)
      end

      def namespace(name, path: nil, **opts, &block)
        define_child(name, path, Namespace, NamespaceWrapper, **opts, &block)
      end

      private

      def define_child(name, path, child_class, wrapper_class, **opts, &block)
        Class.new(child_class).tap do |c|
          c.path = path || "/#{name}"
          c.symbol = name
          c.xml = opts[:xml]

          Addressable::Template.new(c.path).keys.each do |key|
            c.param_set.add key.to_sym, keyword_argument: false
          end

          c.response_processor.parent = @object.response_processor

          wrapper_class.new(c).define(&block) if block

          @object.add_child(c)
        end
      end
    end
    # rubocop:enable Metrics/ParameterLists

    class APIWrapper < NamespaceWrapper
      def base(url)
        @object.base_url = url
      end
    end
  end
end
