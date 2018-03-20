require_relative 'items'

module TLAW
  module DSL
    module Transforms
      class ItemsBatch
        def self.batch(key, &block)
          batcher = new(key)
          batcher.instance_eval(&block)
          batcher.processors
        end

        attr_reader :processors

        def initialize(parent_key)
          @parent_key = parent_key
          @processors = []
        end

        def transform(key = nil, &block)
          tap { @processors << Items.new(@parent_key, key, &block) }
        end

        # Backwards-compatibility
        alias_method :process, :transform
      end
    end
  end
end
