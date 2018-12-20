# frozen_string_literal: true

require_relative 'param/type'

module TLAW
  # @private
  class Param
    attr_reader :name, :field, :type, :description, :default, :format

    def initialize(
      name:,
      field: name,
      type: nil,
      description: nil,
      required: false,
      keyword: true,
      default: nil,
      format: :itself
    )
      @name = name
      @field = field
      @type = Type.coerce(type)
      @description = description
      @required = required
      @keyword = keyword
      @default = default
      @format = format
    end

    def to_h
      {
        name: name,
        field: field,
        type: type,
        description: description,
        required: required?,
        keyword: keyword?,
        default: default,
        format: format
      }
    end

    def required?
      @required
    end

    def keyword?
      @keyword
    end

    def call(value)
      type.(value)
        .yield_self(&format)
        .yield_self { |val| {field => Array(val).join(',')} }
    rescue TypeError => e
      raise TypeError, "#{name}: #{e.message}"
    end
  end
end
