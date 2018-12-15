module TLAW
  module DSL
    class BaseBuilder
      attr_reader :definition

      def initialize(name:, path: nil, **opts, &block)
        path ||= "/#{name}" # Not default arg, because we need to process explicitly passed path: nil, too
        @definition = {name: name, path: path, params: params_from_path(path)}
        instance_eval(&block) if block
      end

      def docs(link)
        @definition[:docs_link] = link
        self
      end

      def description(text)
        @definition[:description] = text
        self
      end

      def param(name, type = nil, **opts)
        opts = opts.merge(type: type) if type
        @definition[:params] ||= {}
        @definition[:params].merge!(name => opts) { |_, o, n| o.merge(n) }
        self
      end

      def finalize
        fail NotImplementedError, "#{self.class} doesn't implement #finalize"
      end

      private

      def params_from_path(path)
        Addressable::Template.new(path).keys.map { |key| [key.to_sym, keyword: false] }.to_h
      end
    end
  end
end