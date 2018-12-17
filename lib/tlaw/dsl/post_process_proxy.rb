# frozen_string_literal: true

module TLAW
  module DSL
    class PostProcessProxy
      def initialize(parent_key, parent)
        @parent_key = parent_key
        @parent = parent
      end

      def post_process(key = nil, &block)
        @parent.add_item_post_processor(@parent_key, key, &block)
      end
    end
  end
end
