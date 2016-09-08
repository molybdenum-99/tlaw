module TLAW
  class Param
    class Type
      attr_reader :type

      def self.parse(options)
        type = options[:type]

        case type
        when nil
          options[:enum] ? EnumType.new(options[:enum]) : Type.new(nil)
        when Class
          ClassType.new(type)
        when Symbol
          DuckType.new(type)
        when Hash
          EnumType.new(type)
        else
          fail ArgumenError, "Undefined type #{type}"
        end
      end

      def initialize(type)
        @type = type
      end

      def convert(value)
        validate(value) && _convert(value)
      end

      def validate(_value)
        true
      end

      def _convert(value)
        value
      end

      def nonconvertible!(value, reason)
        fail Nonconvertible,
             "#{self} can't convert  #{value.inspect}: #{reason}"
      end
    end

    class ClassType < Type
      def validate(value)
        value.respond_to?(type) or
          nonconvertible!(value, "not responding to #{type}")
      end

      def _convert(value)
        value.send(type)
      end
    end

    class DuckType < Type
      def _convert(value)
        value.send(type)
      end

      def validate(value)
        value.respond_to?(type) or
          nonconvertible!(value, "not responding to #{type}")
      end
    end

    class EnumType < Type
      def initialize(enum)
        @type =
          case enum
          when Hash
            enum
          when ->(e) { e.respond_to?(:map) }
            enum.map { |n| [n, n] }.to_h
          else
            fail ArgumentError, "Unparseable enum: #{enum.inspect}"
          end
      end

      def validate(value)
        type.key?(value) or
          nonconvertible!(
            value,
            "is not one of #{type.keys.map(&:inspect).join(', ')}"
          )
      end

      def _convert(value)
        type[value]
      end
    end
  end
end
