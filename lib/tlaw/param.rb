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
      desc: nil,
      description: desc,
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
      # TODO: shouldn't to_s `nil`? Or should drop '' afterwards?..
      # TODO: it had also to_url_part before, joining if the formatter returned array
      type.(value)
        .yield_self(&format)
        .yield_self { |val| {field => val.to_s} }
    rescue TypeError => e
      raise TypeError, "#{name}: #{e.message}"
    end
  end
end
