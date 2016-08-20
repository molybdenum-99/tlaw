require 'open-uri'
require 'json'
require 'addressable'

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

require_relative 'tlaw/shared'

require_relative 'tlaw/api'
require_relative 'tlaw/namespace'
require_relative 'tlaw/endpoint'

require_relative 'tlaw/dsl'
