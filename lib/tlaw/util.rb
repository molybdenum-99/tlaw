# frozen_string_literal: true

module TLAW
  # @private
  module Util
    module_function

    def camelize(string)
      string.sub(/^[a-z\d]*/, &:capitalize)
    end

    def deindent(string)
      string
        .gsub(/^[ \t]+/, '')      # first, remove spaces at a beginning of each line
        .gsub(/\A\n|\n\s*\Z/, '') # then, remove empty lines before and after docs block
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
