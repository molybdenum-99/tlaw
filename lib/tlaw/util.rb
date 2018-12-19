# frozen_string_literal: true

module TLAW
  module Util
    module_function

    def camelize(string)
      string
        .sub(/^[a-z\d]*/, &:capitalize)
        .gsub(%r{(?:_|(/))([a-z\d]*)}i) {
          "#{$1}#{$2.capitalize}" # rubocop:disable Style/PerlBackrefs
        }
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
