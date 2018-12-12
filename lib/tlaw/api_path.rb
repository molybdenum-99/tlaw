# require_relative 'params/set'
require_relative 'has_parent'
require 'forwardable'

module TLAW
  # Base class for all API pathes: entire API, namespaces and endpoints.
  # Allows to define params and post-processors on any level.
  #
  class APIPath
    class << self
      include HasParent
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

      attr_reader :definition

      def setup!(definition)
        @definition = definition.dup
        definition.each{ |a, v| __send__("#{a}=", v) }
      end

      # @private
      def params_from_path!
        Addressable::Template.new(path).keys.each do |key|
          param_set.add key.to_sym, keyword: false
        end
      end

      # @private
      def parent=(parent)
        param_set.parent = parent.param_set
        response_processor.parent = parent.response_processor
        @parent = parent
      end

      # @private
      def symbol=(sym)
        @path ||= "/#{sym}"
        @symbol = sym
      end

      alias name= symbol=

      # @return [Params::Set]
      def param_set
        @param_set ||= Params::Set.new
      end

      def params=(params)
        params.each do |name, **definition|
          param_set.add(name, **definition)
        end
      end

      # @private
      def response_processor
        @response_processor ||= ResponseProcessor.new
      end

      # @private
      def to_method_definition
        params = param_set.to_code
        if params.empty?
          name_to_call.to_s
        else
          "#{name_to_call}(#{params})"
        end
      end

      alias_method :call_sequence, :to_method_definition

      # @private
      alias_method :name_to_call, :symbol

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

      private

      def description_first_para
        description.split("\n\n").first
      end
    end

    include HasParent

    extend Forwardable

    def initialize(parent = nil, **parent_params)
      @parent = parent
      @parent_params = parent_params
    end

    private

    def api
      is_a?(API) ? self : parent&.api
    end

    def object_class
      self.class
    end
  end
end
