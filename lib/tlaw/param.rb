module TLAW
  # Base parameter class for working with parameters validation and
  # converting. You'll never instantiate it directly, just see {DSL#param}
  # for parameters definition.
  #
  class Param
    # This error is thrown when some value could not be converted to what
    # this parameter inspects. For example:
    #
    # ```ruby
    # # definition:
    # param :timestamp, :to_time, format: :to_i
    # # this means: parameter, when passed, will first be converted with
    # # method #to_time, and then resulting time will be made into
    # # unix timestamp with #to_i before passing to API
    #
    # # usage:
    # my_endpoint(timestamp: Time.now) # ok
    # my_endpoint(timestamp: Date.today) # ok
    # my_endpoint(timestamp: '2016-06-01') # Nonconvertible! ...unless you've included ActiveSupport :)
    # ```
    #
    Nonconvertible = Class.new(ArgumentError)

    def self.make(name, **options)
      # NB: Sic. :keyword is nil (not provided) should still
      #     make a keyword argument.
      if options[:keyword] != false
        KeywordParam.new(name, **options)
      else
        ArgumentParam.new(name, **options)
      end
    end

    attr_reader :name, :type, :options

    def initialize(name, **options)
      @name = name
      @options = options
      @type = Type.parse(options)
      @options[:desc] ||= @options[:description]
      @options[:desc].gsub!(/\n( *)/, "\n  ") if @options[:desc]
      @formatter = make_formatter
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
      type.convert(value)
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
        ("[#{doc_type}]" if doc_type),
        description,
        if @options[:enum]
          "\n  Possible values: #{type.values.map(&:inspect).join(', ')}"
        end,
        ("(default = #{default.inspect})" if default)
      ].compact.join(' ')
        .derp(&Util::Description.method(:new))
    end

    private

    attr_reader :formatter

    def doc_type
      type.to_doc_type
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
        return ->(v) { v } unless f
        return f.to_proc if f.respond_to?(:to_proc)
        fail ArgumentError, "#{self}: unsupporter formatter #{f}"
      }
    end

    def default_to_code
      # FIXME: this `inspect` will fail with, say, Time
      default.inspect
    end
  end

  # @private
  class ArgumentParam < Param
    def keyword?
      false
    end

    def to_code
      if required?
        name.to_s
      else
        "#{name}=#{default_to_code}"
      end
    end
  end

  # @private
  class KeywordParam < Param
    def keyword?
      true
    end

    def to_code
      if required?
        "#{name}:"
      else
        "#{name}: #{default_to_code}"
      end
    end
  end
end

require_relative 'param/type'
