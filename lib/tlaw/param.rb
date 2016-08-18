module TLAW
  class Param
    Nonconvertible = Class.new(ArgumentError)

    def initialize(name, type: nil, format: nil, **opts)
      @name = name
      @type = type
      @formatter = prepare_formatter(format)
    end

    def convert(value)
      case @type
      when nil
        value
      when Symbol
        value.respond_to?(@type) or nonconvertible!(value, "not responding to #{@type}")
        value.send(@type)
      when Class
        value.kind_of?(@type) or nonconvertible!(value, "is not #{@type}")
        value
      else
        nonconvertible!(value, "undefined type #{@type}")
      end
    end

    def format(value)
      to_url_part(@formatter.call(value))
    end

    def convert_and_format(value)
      format(convert(value))
    end

    private

    def to_url_part(value)
      case value
      when Array
        value.join(',')
      else
        value.to_s
      end
    end

    def prepare_formatter(formatter)
      case formatter
      when Proc
        formatter
      when ->(f) { f.respond_to?(:to_proc) }
        formatter.to_proc
      when nil
        ->(v) { v }
      else
        fail ArgumentError, "#{self}: unsupporter formatter #{formatter}"
      end
    end

    def nonconvertible!(value, reason)
      fail Nonconvertible, "#{self} can't convert  #{value}: #{reason}"
    end
  end
end
