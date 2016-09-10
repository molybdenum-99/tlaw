module TLAW
  module Util
    module_function

    class Description < String
      alias_method :inspect, :to_s

      def initialize(str)
        super(str.to_s.gsub(/ +\n/, "\n"))
      end

      def indent(indentation = '  ')
        gsub(/(\A|\n)/, '\1' + indentation)
      end

      def +(other)
        self.class.new(super)
      end
    end
  end
end
