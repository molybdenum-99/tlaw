# frozen_string_literal: true

module TLAW
  # @private
  module Formatting
    # @public
    # Description is just a String subclass with rewritten `inspect`
    # implementation (useful in `irb`/`pry`):
    #
    # ```ruby
    # str = "Description of endpoint:\nIt has params:..."
    # # "Description of endpoint:\nIt has params:..."
    #
    # TLAW::Util::Description.new(str)
    # # Description of endpoint:
    # # It has params:...
    # ```
    #
    # TLAW uses it when responds to {APIPath.describe}.
    #
    class Description < String
      alias inspect to_s

      def initialize(str)
        super(str.to_s.gsub(/ +\n/, "\n"))
      end
    end

    module_function

    def call_sequence(klass)
      params = params_to_ruby(klass.param_defs)
      name = klass < API ? "#{klass.name}.new" : klass.symbol.to_s
      params.empty? ? name : "#{name}(#{params})"
    end

    def params_to_ruby(params) # rubocop:disable Metrics/AbcSize
      key, arg = params.partition(&:keyword?)
      req_arg, opt_arg = arg.partition(&:required?)
      req_key, opt_key = key.partition(&:required?)

      # FIXME: default.inspect will fail with, say, Time
      [
        *req_arg.map { |p| p.name.to_s },
        *opt_arg.map { |p| "#{p.name}=#{p.default.inspect}" },
        *req_key.map { |p| "#{p.name}:" },
        *opt_key.map { |p| "#{p.name}: #{p.default.inspect}" }
      ].join(', ')
    end
  end
end

require_relative 'formatting/inspect'
require_relative 'formatting/describe'
