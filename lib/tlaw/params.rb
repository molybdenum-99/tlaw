module TLAW
  class Params
    attr_reader :list

    def initialize(*list)
      @list = list
    end

    def call(**arguments)
      (arguments.keys - list.map(&:name)).yield_self { |unknown|
        unknown.empty? or fail ArgumentError, "Unknown arguments: #{unknown.join(', ')}"
      }

      (required.map(&:name) - arguments.keys).yield_self { |missing|
        missing.empty? or fail ArgumentError, "Missing arguments: #{missing.join(', ')}"
      }

      list
        .map { |par| [par, arguments[par.name]] }
        .reject { |_, v| v.nil? }
        .map { |par, arg| par.(arg) }
        .inject(&:merge)
    end

    def required
      list.select(&:required?)
    end
  end
end

require_relative 'params/type'
require_relative 'params/param'

__END__
  # See `Params::Base` for more info.
  module Params
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
      if options[:keyword] == false
        Argument.new(name, **options)
      else
        Keyword.new(name, **options)
      end
    end
  end
end

require_relative 'params/argument'
require_relative 'params/base'
require_relative 'params/keyword'
require_relative 'params/set'
require_relative 'params/type'
