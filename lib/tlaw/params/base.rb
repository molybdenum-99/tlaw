require_relative 'type'

module TLAW
  module Params
    # Base parameter class for working with parameters validation and
    # converting. You'll never instantiate it directly, just see {DSL#param}
    # for parameters definition.
    #
    class Base
      attr_reader :name, :type, :options

      def initialize(name, **options)
        @name = name
        @options = options
        @type = Type.parse(**options)
        @options[:desc] ||= @options[:description]
        @options[:desc]&.gsub!(/\n( *)/, "\n  ")
        @formatter = make_formatter
      end

      def keyword?
        false
      end

      def required?
        options[:required]
      end

      def default
        options[:default]
      end

      def merge(**new_options)
        Params.make(name, **@options, **new_options)
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
          '@param',
          name,
          ("[#{doc_type}]" if doc_type),
          description,
          ("\n  Possible values: #{type.values.map(&:inspect).join(', ')}" if @options[:enum]),
          ("(default = #{default.inspect})" if default)
        ].compact
          .join(' ')
          .yield_self(&Util::Description.method(:new))
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
        options[:format].yield_self do |f|
          return ->(v) { v } unless f
          return f.to_proc   if f.respond_to?(:to_proc)

          fail ArgumentError, "#{self}: unsupporter formatter #{f}"
        end
      end

      def default_to_code
        # FIXME: this `inspect` will fail with, say, Time
        default.inspect
      end
    end
  end
end
