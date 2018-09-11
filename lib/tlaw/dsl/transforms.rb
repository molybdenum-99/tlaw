module TLAW
  module DSL
    module Transforms
      def self.build(key = nil, replace: false, &block)
        return Key.new(key, &block) if key
        return Replace.new(&block)  if replace

        Base.new(&block)
      end
    end
  end
end

require_relative 'transforms/base'
require_relative 'transforms/items_batch'
require_relative 'transforms/items'
require_relative 'transforms/key'
require_relative 'transforms/replace'
