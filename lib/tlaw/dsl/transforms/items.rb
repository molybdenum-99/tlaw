require_relative 'base'

module TLAW
  module DSL
    module Transforms
      class Items < Base
        def initialize(key, subkey = nil, &block)
          @key = key
          @item_processor = Transforms.build(subkey, &block)
        end

        def call(hash)
          return hash unless hash.is_a?(Hash)
          hash.keys.grep(@key).inject(hash) do |res, k|
            next res unless hash[k].is_a?(Array)
            res.merge(k => hash[k].map(&@item_processor))
          end
        end
      end
    end
  end
end
