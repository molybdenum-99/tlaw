require 'open-uri'
require 'json'
require 'addressable'

# Let no one know! But they in Ruby committee just too long to add
# something like this to the language.
# @private
class Object
  def derp
    yield self
  end
end

module TLAW
end

require_relative 'tlaw/util'
require_relative 'tlaw/data_table'

require_relative 'tlaw/param'
require_relative 'tlaw/param_set'

require_relative 'tlaw/api_object'
require_relative 'tlaw/endpoint'
require_relative 'tlaw/namespace'
require_relative 'tlaw/api'

require_relative 'tlaw/response_processor'

require_relative 'tlaw/dsl'
