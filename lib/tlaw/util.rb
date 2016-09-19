module TLAW
  module Util
    module_function

    def camelize(string)
      string
        .sub(/^[a-z\d]*/, &:capitalize)
        .gsub(%r{(?:_|(/))([a-z\d]*)}i) {
          "#{$1}#{$2.capitalize}" # rubocop:disable Style/PerlBackrefs
        }
    end

    # Description is just a String subclass with rewritten `inspect`
    # implementation (useful in `irb`/`pry`):
    #
    # ```ruby
    # str = "Description of endpoint:\nIt has params:..."
    # # "Description of endpoint:\nIt has params:..."
    #
    # TLAW::Util::Description.new(str)
    # # Description of endpoint:
    # # It has params:...
    # ```
    #
    # TLAW uses it when responds to {APIPath.describe}.
    #
    class Description < String
      alias_method :inspect, :to_s

      def initialize(str)
        super(str.to_s.gsub(/ +\n/, "\n"))
      end

      # @private
      def indent(indentation = '  ')
        gsub(/(\A|\n)/, '\1' + indentation)
      end

      # @private
      def +(other)
        self.class.new(super)
      end
    end
  end
end
