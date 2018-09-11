require_relative 'items'

module TLAW
  module DSL
    module Transforms
      class ItemsBatch
        def self.batch(key, &block)
          new(key)
            .tap { |batcher| batcher.instance_eval(&block) }
            .processors
        end

        attr_reader :processors

        def initialize(parent_key)
          @parent_key = parent_key
          @processors = []
        end

        def transform(key = nil, &block)
          tap { @processors << Items.new(@parent_key, key, &block) }
        end
      end
    end
  end
end
