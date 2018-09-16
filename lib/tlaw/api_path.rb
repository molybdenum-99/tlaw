require_relative 'params/set'
require 'forwardable'

module TLAW
  # Base class for all API pathes: entire API, namespaces and endpoints.
  # Allows to define params and post-processors on any level.
  #
  class APIPath
    class << self
      # @private
      attr_accessor :base_url, :path, :xml, :docs_link

      # @private
      attr_reader :symbol

      # @private
      CLASS_NAMES = {
        :[] => 'Element'
      }.freeze

      # @private
      def class_name
        # TODO:
        # * validate if it is classifiable
        # * provide additional option for non-default class name
        CLASS_NAMES[symbol] || Util.camelize(symbol.to_s)
      end

      # @private
      def description=(descr)
        @description = Util::Description.new(descr)
      end

      # @private
      def description
        return unless @description || @docs_link

        Util::Description.new(
          [@description, ("Docs: #{@docs_link}" if @docs_link)]
            .compact.join("\n\n")
        )
      end

      # @private
      def inherit(namespace, **attrs)
        Class.new(self).tap do |subclass|
          attrs.each { |a, v| subclass.send("#{a}=", v) }
          namespace.const_set(subclass.class_name, subclass)
        end
      end

      # @private
      def params_from_path!
        Addressable::Template.new(path).keys.each do |key|
          param_set.add key.to_sym, keyword: false
        end
      end

      # @private
      def setup_parents(parent)
        param_set.parent = parent.param_set
        response_processor.parent = parent.response_processor
      end

      # @private
      def symbol=(sym)
        @path ||= "/#{sym}"
        @symbol = sym
      end

      # @return [Params::Set]
      def param_set
        @param_set ||= Params::Set.new
      end

      # @private
      def response_processor
        @response_processor ||= ResponseProcessor.new
      end

      # @private
      def to_method_definition
        "#{symbol}(#{param_set.to_code})"
      end

      # Redefined on descendants, it just allows you to do `api.namespace.describe`
      # or `api.namespace1.namespace2.endpoints[:my_endpoint].describe`
      # and have reasonable useful description printed.
      #
      # @return [Util::Description] It is just description string but with
      #   redefined `#inspect` to be pretty-printed in console.
      def describe(definition = nil)
        Util::Description.new(
          ".#{definition || to_method_definition}" +
            (description ? "\n" + description.indent('  ') + "\n" : '') +
            (param_set.empty? ? '' : "\n" + param_set.describe.indent('  '))
        )
      end

      # @private
      def describe_short
        Util::Description.new(
          ".#{to_method_definition}" +
            (description ? "\n" + description_first_para.indent('  ') : '')
        )
      end

      # @private
      def define_method_on(host)
        file, line = method(:to_code).source_location
        # line + 1 is where real definition, theoretically, starts
        host.module_eval(to_code, file, line + 1)
      end

      private

      def description_first_para
        description.split("\n\n").first
      end
    end

    extend Forwardable

    def initialize(**parent_params)
      @parent_params = parent_params
    end

    private

    def object_class
      self.class
    end
  end
end
