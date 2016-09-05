module TLAW
  class Param
    Nonconvertible = Class.new(ArgumentError)

    def self.make(name, **options)
      if options[:keyword_argument] != false
        KeywordParam.new(name, **options)
      else
        ArgumentParam.new(name, **options)
      end
    end

    attr_reader :name, :options

    def initialize(name, **options)
      @name = name
      @options = options
      process_enum
      @options[:desc] ||= @options[:description]
      @options[:desc].gsub!(/\n( *)/, "\n  ") if @options[:desc]
      @formatter = make_formatter
    end

    def type
      options[:type]
    end

    def required?
      options[:required]
    end

    def default
      options[:default]
    end

    def merge(**new_options)
      Param.make(name, @options.merge(new_options))
    end

    def field
      options[:field] || name
    end

    def convert(value)
      case type
      when nil
        value
      when Symbol
        value.respond_to?(type) or
          nonconvertible!(value, "not responding to #{type}")
        value.send(type)
      when Class
        value.is_a?(type) or
          nonconvertible!(value, "is not #{type}")
        value
      when Hash
        type.key?(value) or
          nonconvertible!(value, "is not one of #{type.keys.map(&:inspect).join(', ')}")

        type[value]
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

    def description
      options[:desc]
    end

    def describe
      [
        '@param', name,
        if doc_type then "[#{doc_type}]" end,
        description,
        if @options[:enum]
          "\n  Possible values: #{options[:enum].map(&:inspect).join(', ')}"
        end,
        if default then "(default = #{default.inspect})" end
      ].compact.join(' ')
        .derp(&Util::Description.method(:new))
    end

    private

    attr_reader :formatter

    def doc_type
      case type
      when Symbol
        "##{type}"
      when Class
        type.name
      else
        nil
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

    def make_formatter
      options[:format].derp { |f|
        case f
        when Proc
          f
        when ->(ff) { ff.respond_to?(:to_proc) }
          f.to_proc
        when nil
          ->(v) { v }
        else
          fail ArgumentError, "#{self}: unsupporter formatter #{f}"
        end
      }
    end

    def nonconvertible!(value, reason)
      fail Nonconvertible, "#{self} can't convert  #{value.inspect}: #{reason}"
    end

    def process_enum
      @options[:enum].tap { |enum|
        return unless enum
        @options[:type] =
          case enum
          when Hash
            enum
          when Array
            enum.map { |n| [n, n] }.to_h
          else
            fail ArgumentError, "Unparseable enum: #{enum.inspect}"
          end
      }
    end
  end

  class ArgumentParam < Param
    def keyword_argument?
      false
    end

    def to_code
      if required?
        name.to_s
      else
        # FIXME: this `inspect` will fail with, say, Time
        "#{name}=#{default.inspect}"
      end
    end
  end

  class KeywordParam < Param
    def keyword_argument?
      true
    end

    def to_code
      if required?
        "#{name}:"
      else
        # FIXME: this `inspect` will fail with, say, Time
        "#{name}: #{default.inspect}"
      end
    end
  end
end
