module TLAW
  # FIXME: everything is awfully dirty here
  class ResponseProcessor
    class Base
      def initialize(&block)
        @block = block
      end

      def call(hash)
        hash.tap(&@block)
      end

      def to_proc
        method(:call).to_proc
      end
    end

    class Key < Base
      def initialize(key, &block)
        @key = key
        super(&block)
      end

      def call(hash)
        return hash unless hash.is_a?(Hash) && hash.key?(@key)

        hash.merge(@key => @block.call(hash[@key]))
      end
    end

    class Items < Base
      def initialize(key, subkey = nil, &block)
        @key = key
        @item_processor = subkey ? Key.new(subkey, &block) : Base.new(&block)
      end

      def call(hash)
        return hash unless hash.key?(@key)
        return hash unless hash[@key].is_a?(Array)

        hash.merge(@key => hash[@key].map(&@item_processor))
      end
    end

    def initialize
      @post_processors = []
    end

    def add_post_processor(key = nil, &block)
      @post_processors << (key ? Key.new(key, &block) : Base.new(&block))
    end

    def add_item_post_processor(key, subkey = nil, &block)
      @post_processors << Items.new(key, subkey, &block)
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
      }.reject { |_, v| v.nil? }.to_h
    end

    def post_process(hash)
      @post_processors.inject(hash) { |res, processor|
        processor.call(res).derp(&method(:flatten))
      }
    end

    def datablize(hash)
      hash.map { |k, v|
        if v.is_a?(Array) && !v.empty? && v.all? { |v1| v1.is_a?(Hash) }
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
