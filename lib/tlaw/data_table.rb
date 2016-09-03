module TLAW
  class DataTable < Array
    def initialize(hashes)
      hashes = hashes.each_with_index.map { |h, i|
        h.is_a?(Hash) or
          fail ArgumentError,
               "All rows are expected to be hashes, row #{i} is #{h.class}"

        h.map { |k, v| [k.to_s, v] }.to_h
      }
      empty = hashes.map(&:keys).flatten.uniq.map { |k| [k, nil] }.to_h
      hashes = hashes.map { |h| empty.merge(h) }
      super(hashes)
    end

    def keys
      empty? ? [] : first.keys
    end

    def [](index_or_column)
      case index_or_column
      when Integer
        super
      when String, Symbol
        map { |h| h[index_or_column.to_s] }
      else
        fail ArgumentError,
             'Expected integer or string/symbol index' \
             ", got #{index_or_column.class}"
      end
    end

    def columns(*names)
      names.map!(&:to_s)
      DataTable.new(map { |h| names.map { |n| [n, h[n]] }.to_h })
    end

    def to_h
      keys.map { |k| [k, map { |h| h[k] }] }.to_h
    end

    def inspect
      "#<#{self.class.name}[#{keys.join(', ')}] x #{size}>"
    end

    def pretty_print(pp)
      pp.text("#<#{self.class.name}[#{keys.join(', ')}] x #{size}>")
    end
  end
end
