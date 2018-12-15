# require_relative 'params/set'
require_relative 'has_parent'
require 'forwardable'
require_relative 'inspect'

module TLAW
  # Base class for all API pathes: entire API, namespaces and endpoints.
  # Allows to define params and post-processors on any level.
  #
  class APIPath
    class << self
      # @private
      attr_reader :symbol, :parent, :path, :param_defs, :docs_link
      attr_writer :parent

      def define(symbol:, path:, param_defs: [], description: nil, docs_link: nil)
        Class.new(self).tap do |subclass|
          subclass.symbol = symbol
          subclass.path = path
          subclass.param_defs = param_defs
          subclass.description = description
          subclass.docs_link = docs_link
        end
      end

      def full_param_defs
        [*parent&.full_param_defs, *param_defs]
      end

      def required_param_defs
        param_defs.select(&:required?)
      end

      def url_template
        parent&.url_template or fail RuntimeError, "Orphan path #{path}, can't determine full URL"
        [parent.url_template, path].join
      end

      def parents
        Util.parents(self)
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
      def response_processor
        @response_processor ||= ResponseProcessor.new
      end

      protected

      attr_writer :symbol, :param_defs, :path, :description, :xml, :docs_link
    end

    include HasParent

    extend Forwardable

    def initialize(parent, **params)
      @parent = parent
      @params = params
    end

    def prepared_params
      (parent&.prepared_params || {}).merge(prepare_params(@params))
    end

    private

    def_delegators :self_class, :param_defs, :required_param_defs

    def prepare_params(arguments)
      guard_missing!(arguments)
      guard_unknown!(arguments)

      param_defs
        .map { |dfn| [dfn, arguments[dfn.name]] }
        .reject { |_, v| v.nil? }
        .map { |dfn, arg| dfn.(arg) }
        .inject(&:merge)
    end

    def guard_unknown!(arguments)
      arguments.keys.-(param_defs.map(&:name)).yield_self { |unknown|
        unknown.empty? or fail ArgumentError, "Unknown arguments: #{unknown.join(', ')}"
      }
    end

    def guard_missing!(arguments)
      required_param_defs.map(&:name).-(arguments.keys).yield_self { |missing|
        missing.empty? or fail ArgumentError, "Missing arguments: #{missing.join(', ')}"
      }
    end

    def api
      is_a?(API) ? self : parent&.api
    end

    # For def_delegators
    def self_class
      self.class
    end
  end
end
