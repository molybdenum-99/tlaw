module TLAW
  module DSL
    class BaseBuilder
      attr_reader :params

      def initialize(symbol:, path: nil, **opts, &block)
        path ||= "/#{symbol}" # Not default arg, because we need to process explicitly passed path: nil, too
        @definition = {symbol: symbol, path: path, }
        @params = params_from_path(path)
        instance_eval(&block) if block
      end

      def definition
        @definition.merge(param_defs: params.map { |name, **opts| Param.new(name: name, **opts)})
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

      def post_process(*) end
      def post_process_items(*) end

      private

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