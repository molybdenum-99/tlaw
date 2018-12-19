# frozen_string_literal: true

module TLAW
  # @private
  module Util
    module_function

    def camelize(string)
      string.sub(/^[a-z\d]*/, &:capitalize)
    end

    # Returns [parent, parent.parent, ...]
    def parents(obj)
      result = []
      cursor = obj
      while (cursor = cursor.parent)
        result << cursor
      end
      result
    end
  end
end
