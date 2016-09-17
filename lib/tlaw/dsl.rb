module TLAW
  module DSL
    # @private
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

      def docs(link)
        @object.docs_link = link
      end

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

    # @private
    class EndpointWrapper < BaseWrapper
    end

    # @private
    class NamespaceWrapper < BaseWrapper
      def endpoint(name, path = nil, **opts, &block)
        update_existing(Endpoint, name, path, **opts, &block) ||
          add_child(Endpoint, name, path: path || "/#{name}", **opts, &block)
      end

      def namespace(name, path = nil, &block)
        update_existing(Namespace, name, path, &block) ||
          add_child(Namespace, name, path: path || "/#{name}", &block)
      end

      private

      WRAPPERS = {
        Endpoint => EndpointWrapper,
        Namespace => NamespaceWrapper
      }.freeze

      def update_existing(child_class, name, path, **opts, &block)
        existing = @object.children[name] or return nil
        existing < child_class or
          fail ArgumentError, "#{name} is already defined as #{child_class == Endpoint ? 'namespace' : 'endpoint'}, you can't redefine it as #{child_class}"

        !path && opts.empty? or
          fail ArgumentError, "#{child_class} is already defined, you can't change its path or options"

        WRAPPERS[child_class].new(existing).define(&block) if block
      end

      def add_child(child_class, name, **opts, &block)
        @object.add_child(
          child_class.inherit(@object, symbol: name, **opts)
          .tap { |c| c.setup_parents(@object) }
          .tap(&:params_from_path!)
          .tap { |c|
            WRAPPERS[child_class].new(c).define(&block) if block
          }
        )
      end
    end

    # @private
    class APIWrapper < NamespaceWrapper
      def base(url)
        @object.base_url = url
      end
    end
  end
end
