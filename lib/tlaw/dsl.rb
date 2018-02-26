module TLAW
  # This module is core of a TLAW API definition. It works like this:
  #
  # ```ruby
  # class MyAPI < TLAW::API
  #   define do # here starts what DSL does
  #     namespace :ns do
  #
  #       endpoint :es do
  #         param :param1, Integer, default: 1
  #       end
  #     end
  #   end
  # end
  # ```
  #
  # Methods of current namespace documentation describe everything you
  # can use inside `define` blocks. Actual structure of things is a bit
  # more complicated (relate to lib/tlaw/dsl.rb if you wish), but current
  # documentation structure considered to be most informative.
  #
  module DSL
  end
end

require_relative 'dsl/api_wrapper'
require_relative 'dsl/base_wrapper'
require_relative 'dsl/endpoint_wrapper'
require_relative 'dsl/namespace_wrapper'
require_relative 'dsl/post_process_proxy'
