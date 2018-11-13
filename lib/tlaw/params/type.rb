module TLAW
  module Params
    # @private
    class Type
      attr_reader :type

      def self.parse(type: nil, enum: nil, **)
        case type
        when nil
          enum ? EnumType.new(enum) : Type.new(nil)
        when Class
          ClassType.new(type)
        when Symbol
          DuckType.new(type)
        when Hash
          EnumType.new(type)
        else
          fail ArgumentError, "Undefined type #{type}"
        end
      end

      def initialize(type)
        @type = type
      end

      def to_doc_type
        nil
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

    # @private
    class ClassType < Type
      def validate(value)
        value.is_a?(type) or
          nonconvertible!(value, "not an instance of #{type}")
      end

      def _convert(value)
        value
      end

      def to_doc_type
        type.name
      end
    end

    # @private
    class DuckType < Type
      def _convert(value)
        value.send(type)
      end

      def validate(value)
        value.respond_to?(type) or
          nonconvertible!(value, "not responding to #{type}")
      end

      def to_doc_type
        "##{type}"
      end
    end

    # @private
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

      def values
        type.keys
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
