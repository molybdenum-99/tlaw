module TLAW
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
  end
end

require_relative 'params/argument'
require_relative 'params/keyword'
require_relative 'params/param'
require_relative 'params/set'
require_relative 'params/type'
