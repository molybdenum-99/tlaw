module TLAW
  module Util
    module_function

    def camelize(string)
      string.to_s
        .sub(/^[a-z\d]*/) { |l| l.capitalize }
        .gsub(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
    end

    def flatten_hashes(val)
      case val
      when Array
        val.map { |e| flatten_hashes(e) }
      when Hash
        flatten_hash(val)
      else
        val
      end
    end

    def flatten_hash(hash)
      hash.map { |k, v|
        case v
        when Hash
          flatten_hash(v).map { |k1, v1| ["#{k}.#{k1}", v1] }
        when Array
          if v.all? {|v1| v1.is_a?(Hash) }
            [[k, DataTable.new(flatten_hashes(v))]]
          else
            [[k, flatten_hashes(v)]]
          end
        else
          [[k, flatten_hashes(v)]]
        end
      }.flatten(1).to_h
    end

    class Description < String
      alias_method :inspect, :to_s

      def indent(indentation = '  ')
        gsub(/(\A|\n)/, '\1' + indentation)
      end
    end
  end
end
