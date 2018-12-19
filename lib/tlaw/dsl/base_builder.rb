# frozen_string_literal: true

module TLAW
  module DSL
    # @private
    class BaseBuilder
      attr_reader :params, :processors

      def initialize(symbol:, path: nil, context: nil, xml: false, params: {}, **opts, &block)
        path ||= "/#{symbol}" # Not default arg, because we need to process explicitly passed path: nil, too
        @definition = opts.merge(symbol: symbol, path: path)
        @params = params.merge(params_from_path(path))
        @processors = (context&.processors || []).dup
        @parser = parser(xml)
        instance_eval(&block) if block
      end

      def definition
        @definition.merge(param_defs: params.map { |name, **opts| Param.new(name: name, **opts) })
      end

      def docs(link)
        @definition[:docs_link] = link
        self
      end

      def description(text)
        @definition[:description] = text
        self
      end

      alias desc description

      def param(name, type = nil, enum: nil, **opts)
        opts = opts.merge(type: type) if type
        opts = opts.merge(type: enum_type(enum)) if enum
        params.merge!(name => opts) { |_, o, n| o.merge(n) }
        self
      end

      def finalize
        fail NotImplementedError, "#{self.class} doesn't implement #finalize"
      end

      G = ResponseProcessors::Generators

      def post_process(key_pattern = nil, &block)
        @processors << (key_pattern ? G.transform_by_key(key_pattern, &block) : G.mutate(&block))
      end

      # @private
      class PostProcessProxy
        def initialize(owner, parent_key)
          @owner = owner
          @parent_key = parent_key
        end

        def post_process(key = nil, &block)
          @owner.processors << G.transform_nested(@parent_key, key, &block)
        end
      end

      def post_process_items(key_pattern, &block)
        PostProcessProxy.new(self, key_pattern).instance_eval(&block)
      end

      def post_process_replace(&block)
        @processors << block
      end

      private

      def parser(xml)
        xml ? Crack::XML.method(:parse) : JSON.method(:parse)
      end

      def enum_type(enum)
        case enum
        when Hash
          enum
        when Enumerable # well... in fact respond_to?(:each) probably will do
          enum.map { |v| [v, v] }.to_h
        else
          fail ArgumentError, "Can't construct enum from #{enum.inspect}"
        end
      end

      def params_from_path(path)
        Addressable::Template.new(path).keys.map { |key| [key.to_sym, keyword: false] }.to_h
      end
    end
  end
end
