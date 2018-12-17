# frozen_string_literal: true

module TLAW
  # Basically, just a 2-d array with column names. Or you can think of
  # it as an array of hashes. Or loose DataFrame implementation.
  #
  # Just like this:
  #
  # ```ruby
  # tbl = DataTable.new([
  #   {id: 1, name: 'Mike', salary: 1000},
  #   {id: 2, name: 'Doris', salary: 900},
  #   {id: 3, name: 'Angie', salary: 1200}
  # ])
  # # => #<TLAW::DataTable[id, name, salary] x 3>
  # tbl.count
  # # => 3
  # tbl.keys
  # # => ["id", "name", "salary"]
  # tbl[0]
  # # => {"id"=>1, "name"=>"Mike", "salary"=>1000}
  # tbl['salary']
  # # => [1000, 900, 1200]
  # ```
  #
  # Basically, that's it. Every array of hashes in TLAW response will be
  # converted into corresponding `DataTable`.
  #
  class DataTable < Array
    def self.from_columns(column_names, columns)
      from_rows(column_names, columns.transpose)
    end

    def self.from_rows(column_names, rows)
      new(rows.map { |r| column_names.zip(r).to_h })
    end

    # Creates DataTable from array of hashes.
    #
    # Note, that all hash keys are stringified, and all hashes are expanded
    # to have same set of keys.
    #
    # @param hashes [Array<Hash>]
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

    # All column names.
    #
    # @return [Array<String>]
    def keys
      empty? ? [] : first.keys
    end

    # Allows access to one column or row.
    #
    # @overload [](index)
    #   Returns one row from a DataTable.
    #
    #   @param index [Integer] Row number
    #   @return [Hash] Row as a hash
    #
    # @overload [](column_name)
    #   Returns one column from a DataTable.
    #
    #   @param column_name [String] Name of column
    #   @return [Array] Column as an array of all values in it
    #
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

    # Slice of a DataTable with only specified columns left.
    #
    # @param names [Array<String>] What columns to leave in a DataTable
    # @return [DataTable]
    def columns(*names)
      names.map!(&:to_s)
      DataTable.new(map { |h| names.map { |n| [n, h[n]] }.to_h })
    end

    # Represents DataTable as a `column name => all values in columns`
    # hash.
    #
    # @return [Hash{String => Array}]
    def to_h
      keys.map { |k| [k, map { |h| h[k] }] }.to_h
    end

    # @private
    def inspect
      "#<#{self.class.name}[#{keys.join(', ')}] x #{size}>"
    end

    # @private
    def pretty_print(printer)
      printer.text("#<#{self.class.name}[#{keys.join(', ')}] x #{size}>")
    end
  end
end
