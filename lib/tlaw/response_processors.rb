# frozen_string_literal: true

module TLAW
  # @private
  module ResponseProcessors
    # @private
    module Generators
      module_function

      def mutate(&block)
        proc { |hash| hash.tap(&block) }
      end

      def transform_by_key(key_pattern, &block)
        proc { |hash| ResponseProcessors.transform_by_key(hash, key_pattern, &block) }
      end

      def transform_nested(key_pattern, nested_key_pattern = nil, &block)
        transformer = if nested_key_pattern
                        transform_by_key(nested_key_pattern, &block)
                      else
                        mutate(&block)
                      end
        proc { |hash| ResponseProcessors.transform_nested(hash, key_pattern, &transformer) }
      end
    end

    class << self
      def transform_by_key(value, key_pattern)
        return value unless value.is_a?(Hash)

        value
          .map { |k, v| key_pattern === k ? [k, yield(v)] : [k, v] } # rubocop:disable Style/CaseEquality
          .to_h
      end

      def transform_nested(value, key_pattern, &block)
        transform_by_key(value, key_pattern) { |v| v.is_a?(Array) ? v.map(&block) : v }
      end

      def flatten(value)
        case value
        when Hash
          flatten_hash(value)
        when Array
          value.map(&method(:flatten))
        else
          value
        end
      end

      def datablize(value)
        case value
        when Hash
          value.transform_values(&method(:datablize))
        when Array
          if !value.empty? && value.all?(Hash)
            DataTable.new(value)
          else
            value
          end
        else
          value
        end
      end

      private

      def flatten_hash(hash)
        hash.flat_map do |k, v|
          v = flatten(v)
          if v.is_a?(Hash)
            v.map { |k1, v1| ["#{k}.#{k1}", v1] }
          else
            [[k, v]]
          end
        end.reject { |_, v| v.nil? }.to_h
      end
    end
  end
end
