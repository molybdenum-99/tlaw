module TLAW
  module Params
    # @private
    class Type
      attr_reader :type

      def self.coerce(type = nil)
        case type
        when nil
          new(nil)
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

      def call(value)
        validation_error(value)
          &.yield_self { |msg|
            fail TypeError, "expected #{msg}, got #{value.inspect}"
          }
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
        "instance of #{type}" unless value.is_a?(type)
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
        "object responding to ##{type}" unless value.respond_to?(type)
      end

      def to_doc_type
        "##{type}"
      end
    end

    # @private
    class EnumType < Type
      def possible_values
        type.keys.map(&:inspect).join(', ')
      end

      def validation_error(value)
        "one of #{possible_values}" unless type.key?(value)
      end

      def _convert(value)
        type.fetch(value)
      end
    end
  end
end
