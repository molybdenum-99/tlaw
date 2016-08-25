module TLAW
  class Param
    Nonconvertible = Class.new(ArgumentError)

    DEFAULT_OPTIONS = {keyword_argument: true}.freeze

    attr_reader :name, :options

    def initialize(name, **options)
      @name = name
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def type
      options[:type]
    end

    def required?
      options[:required]
    end

    def keyword_argument?
      options[:keyword_argument]
    end

    def common?
      options[:common]
    end

    def update(**new_options)
      @options.update(new_options)
    end

    def convert(value)
      case type
      when nil
        value
      when Symbol
        value.respond_to?(type) or nonconvertible!(value, "not responding to #{type}")
        value.send(type)
      when Class
        value.kind_of?(type) or nonconvertible!(value, "is not #{type}")
        value
      else
        nonconvertible!(value, "undefined type #{type}")
      end
    end

    def format(value)
      to_url_part(formatter.call(value))
    end

    def convert_and_format(value)
      format(convert(value))
    end

    alias_method :to_h, :options

    def to_code
      default = options[:default]

      case
      when keyword_argument? && required?
        "#{name}:"
      when keyword_argument?
        "#{name}: #{default.inspect}"
      when required?
        "#{name}"
      else
        "#{name}=#{default.inspect}"
      end
    end

    def describe
      Util::Description.new("@param #{name} [#{doc_type}]")
    end

    private

    def doc_type
      case type
      when nil
        '#to_s'
      when Symbol
        "##{type}"
      when Class
        type.name
      end
    end
    def to_url_part(value)
      case value
      when Array
        value.join(',')
      else
        value.to_s
      end
    end

    def formatter
      @formatter ||=
        case options[:format]
        when Proc
          options[:format]
        when ->(f) { f.respond_to?(:to_proc) }
          options[:format].to_proc
        when nil
          ->(v) { v }
        else
          fail ArgumentError, "#{self}: unsupporter formatter #{options[:format]}"
        end
    end

    def nonconvertible!(value, reason)
      fail Nonconvertible, "#{self} can't convert  #{value}: #{reason}"
    end
  end
end
