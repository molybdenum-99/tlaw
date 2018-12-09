module TLAW
  module DSL
    class BaseBuilder
      attr_reader :definition

      def initialize(name:, path: "/#{name}", **opts, &block)
        @definition = {name: name, path: path, params: params_from_path(path)}
        instance_eval(&block) if block
      end

      def docs(link)
        @definition[:docs] = link
        self
      end

      def description(text)
        # first, remove spaces at a beginning of each line
        # then, remove empty lines before and after docs block
        #
        # FIXME: It is just a loose imitation of Ruby 2.3's "squiggly heredoc". Maybe we don't need
        # it anymore?..
        @definition[:description] =
          text
          .gsub(/^[ \t]+/, '')
          .gsub(/\A\n|\n\s*\Z/, '')
        self
      end

      def param(name, type = nil, **opts)
        opts = opts.merge(type: type) if type
        @definition[:params] ||= {}
        @definition[:params].merge!(name => opts) { |k, o, n| o.merge(n) }
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