module TLAW
  # FIXME: everything is awfully dirty here
  class ResponseProcessor
    def initialize
      @post_processors = []
    end

    def add_post_processor(key = nil, &block)
      @post_processors << [key, block]
    end

    def add_item_post_processor(key, subkey = nil, &block)
      @post_processors << [key, ->(array) {
        next array unless array.is_a?(Array)
        array.map { |h|
          if subkey
            if h[subkey]
              h.merge(subkey => block.call(h[subkey]))
            else
              h
            end
          else
            block.call(h)
            h
          end.reject { |_, v| v.nil? }
        }
      }]
    end

    def flatten(hash)
      hash.flat_map { |k, v|
        case v
        when Hash
          flatten(v).map { |k1, v1| ["#{k}.#{k1}", v1] }
        when Array
          if v.all? { |v1| v1.is_a?(Hash) }
            [[k, v.map(&method(:flatten))]]
          else
            [[k, v]]
          end
        else
          [[k, v]]
        end
      }.to_h
    end

    def post_process(hash)
      @post_processors.inject(hash) { |res, (key, block)|
        if key
          if res.key?(key)
            res.merge(key => block.call(res[key]))
          else
            res
          end
        else
          block.call(res)
          res
        end.derp(&method(:flatten))
      }.reject { |_, v| v.nil? }
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

    def process(hash)
      flatten(hash).derp(&method(:post_process)).derp(&method(:datablize))
    end
  end
end
