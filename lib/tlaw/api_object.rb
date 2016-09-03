module TLAW
  class APIObject
    class << self
      attr_accessor :base_url, :path
      attr_reader :description

      def symbol
        @symbol || (name && "#{name}.new") or
          fail(ArgumentError, "Undescribed API object #{self}")
      end

      def description=(descr)
        @description = Util::Description.new(descr)
      end

      def symbol=(sym)
        @symbol = sym
        @path ||= "/#{sym}"
      end

      def param_set
        @param_set ||= ParamSet.new
      end

      def to_method_definition
        "#{symbol}(#{param_set.to_code})"
      end

      def describe
        Util::Description.new(
          ".#{to_method_definition}" +
            (description ? "\n" + description.indent('  ') + "\n" : '') +
            (param_set.empty? ? '' : "\n" + param_set.describe.indent('  '))
        )
      end

      def describe_short
        Util::Description.new(
          ".#{to_method_definition}" +
            (description ? "\n" + description.split("\n\n").first.indent('  ') : '')
        )
      end

      def define_method_on(host)
        file, line = method(:to_code).source_location
        # line + 1 is where real definition, theoretically, starts
        host.module_eval(to_code, file, line + 1)
      end
    end

    def initialize(**parent_params)
      @parent_params = parent_params
    end
  end
end
