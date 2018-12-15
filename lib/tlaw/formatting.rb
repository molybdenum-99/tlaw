module TLAW
  module Formatting
    module_function

    def call_sequence(klass)
      params = params_to_ruby(klass.param_defs)
      name = klass < API ? "#{klass.name}.new" : klass.symbol.to_s
      params.empty? ? name : "#{name}(#{params})"
    end

    def params_to_ruby(params)
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
