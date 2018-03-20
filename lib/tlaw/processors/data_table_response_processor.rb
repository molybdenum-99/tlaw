require_relative 'response_processor'

module TLAW
  module Processors
    # FIXME: everything is awfully dirty here
    class DataTableResponseProcessor < ResponseProcessor
      def call(response)
        datablize super
      end

      private

      def parse_response(response)
        flatten super
      end

      def apply(processor, res)
        flatten super
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

      def datablize(value)
        case value
        when Hash
          value.map { |k, v| [k, datablize(v)] }.to_h
        when Array
          if !value.empty? && value.all? { |el| el.is_a?(Hash) }
            DataTable.new(value)
          else
            value
          end
        else
          value
        end
      end
    end
  end
end
