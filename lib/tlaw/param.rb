module TLAW
  class Param
    Nonconvertible = Class.new(ArgumentError)

    DEFAULT_DEFINITION = {keyword_argument: true}.freeze

    attr_reader :name, :definition

    def initialize(name, **definition)
      @name = name
      @definition = DEFAULT_DEFINITION.merge(definition)
    end

    def type
      definition[:type]
    end

    def required?
      definition[:required]
    end

    def keyword_argument?
      definition[:keyword_argument]
    end

    def common?
      definition[:common]
    end

    def update(**new_definition)
      @definition.update(new_definition)
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

    alias_method :to_h, :definition

    def generate_definition
      default = definition[:default]

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

    private

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
        case definition[:format]
        when Proc
          definition[:format]
        when ->(f) { f.respond_to?(:to_proc) }
          definition[:format].to_proc
        when nil
          ->(v) { v }
        else
          fail ArgumentError, "#{self}: unsupporter formatter #{definition[:format]}"
        end
    end

    def nonconvertible!(value, reason)
      fail Nonconvertible, "#{self} can't convert  #{value}: #{reason}"
    end
  end
end
