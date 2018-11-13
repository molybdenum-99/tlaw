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
        if (err = validation_error(value))
          fail Nonconvertible,
               "#{self} can't convert  #{value.inspect}: #{err}"
        end
        _convert(value)
      end

      def validation_error(_value)
        nil
      end

      def _convert(value)
        value
      end
    end

    # @private
    class ClassType < Type
      def validation_error(value)
        "not an instance of #{type}" unless value.is_a?(type)
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

      def validation_error(value)
        "not responding to #{type}" unless value.respond_to?(type)
      end

      def to_doc_type
        "##{type}"
      end
    end

    # @private
    class EnumType < Type
      def initialize(enum)
        super(
          case enum
          when Hash
            enum
          when ->(e) { e.respond_to?(:map) }
            enum.map { |n| [n, n] }.to_h
          else
            fail ArgumentError, "Unparseable enum: #{enum.inspect}"
          end
        )
      end

      def possible_values
        type.keys.map(&:inspect).join(', ')
      end

      def validation_error(value)
        "is not one of #{possible_values}" unless type.key?(value)
      end

      def _convert(value)
        type[value]
      end
    end
  end
end
