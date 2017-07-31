module TLAW
  # @private
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
        return hash unless hash.is_a?(Hash)
        hash.keys.grep(@key).inject(hash) do |res, k|
          res.merge(k => @block.call(hash[k]))
        end
      end
    end

    class Replace < Base
      def call(hash)
        @block.call(hash)
      end
    end

    class Items < Base
      def initialize(key, subkey = nil, &block)
        @key = key
        @item_processor = subkey ? Key.new(subkey, &block) : Base.new(&block)
      end

      def call(hash)
        return hash unless hash.is_a?(Hash)
        hash.keys.grep(@key).inject(hash) do |res, k|
          next res unless hash[k].is_a?(Array)
          res.merge(k => hash[k].map(&@item_processor))
        end
      end
    end

    attr_reader :post_processors
    attr_accessor :parent

    def initialize(post_processors = [])
      @post_processors = post_processors
    end

    def add_post_processor(key = nil, &block)
      @post_processors << (key ? Key.new(key, &block) : Base.new(&block))
    end

    def add_replacer(&block)
      @post_processors << Replace.new(&block)
    end

    def add_item_post_processor(key, subkey = nil, &block)
      @post_processors << Items.new(key, subkey, &block)
    end

    def process(hash)
      flatten(hash).derp(&method(:post_process)).derp(&method(:datablize))
    end

    def all_post_processors
      [*(parent ? parent.all_post_processors : nil), *@post_processors]
    end

    private

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
      hash.flat_map { |k, v|
        v = flatten(v)
        if v.is_a?(Hash)
          v.map { |k1, v1| ["#{k}.#{k1}", v1] }
        else
          [[k, v]]
        end
      }.reject { |_, v| v.nil? }.to_h
    end

    def post_process(hash)
      all_post_processors.inject(hash) { |res, processor|
        processor.call(res).derp(&method(:flatten))
      }
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
