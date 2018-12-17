# frozen_string_literal: true

module TLAW
  module HasParent
    attr_reader :parent

    # Returns [parent, parent.parent, ...]
    def parents
      result = []
      cursor = self
      while (cursor = cursor.parent)
        result << cursor
      end
      result
    end
  end
end
