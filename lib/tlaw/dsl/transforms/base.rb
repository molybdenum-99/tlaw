module TLAW
  module DSL
    module Transforms
      class Base
        def initialize(&block)
          @block = block
        end

        def call(hash)
          hash.tap(&@block)
        end

        def to_proc
          method(:call).to_proc
        end
      end
    end
  end
end
