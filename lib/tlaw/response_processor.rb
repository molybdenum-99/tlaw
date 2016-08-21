module TLAW
  class ResponseProcessor
    class << self
      def post_process(key = nil, &block)
        post_processors << [key, block]
      end

      def post_process_each(key, subkey = nil, &block)
        post_processors << [key, ->(array) {
          next array unless array.is_a?(Array)
          array.map { |h|
            if subkey
              h.merge(subkey => block.call(h[subkey]))
            else
              block.call(h)
              h
            end.reject { |k, v| v.nil? }
          }
        }]
      end

      def post_processors
        @post_processors ||= []
      end

      def list_post_processors
        @list_post_processors ||= {}
      end
    end

    def flatten(hash)
      hash.map { |k, v|
        case v
        when Hash
          flatten(v).map { |k1, v1| ["#{k}.#{k1}", v1] }
        when Array
          if v.all? {|v1| v1.is_a?(Hash) }
            [[k, v.map(&method(:flatten))]]
          else
            [[k, v]]
          end
        else
          [[k, v]]
        end
      }.flatten(1).to_h
    end

    def post_process(hash)
      self.class.post_processors.inject(hash) { |res, (key, block)|
        if key
          res.merge(key => block.call(res[key]))
        else
          block.call(res)
          res
        end
      }.reject { |k, v| v.nil? }
    end

    def datablize(hash)
      hash.map { |k, v|
        if v.is_a?(Array) && v.all? { |v1| v1.is_a?(Hash) }
          [k, DataTable.new(v)]
        else
          [k, v]
        end
      }.to_h
    end
  end
end
