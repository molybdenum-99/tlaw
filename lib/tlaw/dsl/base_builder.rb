# frozen_string_literal: true

module TLAW
  module DSL
    # @private
    class BaseBuilder
      attr_reader :params, :processors, :shared_definitions

      def initialize(symbol:, path: nil, context: nil, xml: false, params: {}, **opts, &block)
        path ||= "/#{symbol}" # Not default arg, because we need to process explicitly passed path: nil, too
        @definition = opts.merge(symbol: symbol, path: path)
        @params = params.merge(params_from_path(path))
        @processors = (context&.processors || []).dup
        @parser = parser(xml)
        @shared_definitions = context&.shared_definitions || {}
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
        @definition[:description] = Util.deindent(text)
        self
      end

      alias desc description

      def param(name, type = nil, enum: nil, desc: nil, description: desc, **opts)
        opts = opts.merge(
          type: type || enum&.yield_self(&method(:enum_type)),
          description: description&.yield_self(&Util.method(:deindent))
        ).compact
        params.merge!(name => opts) { |_, o, n| o.merge(n) }
        self
      end

      def shared_def(name, &block)
        @shared_definitions[name] = block
        self
      end

      def use_def(name)
        shared_definitions
          .fetch(name) { fail ArgumentError, "#{name.inspect} is not a shared definition" }
          .tap { |block| instance_eval(&block) }
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
