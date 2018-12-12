module TLAW
  module Params
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
        @format = format.to_proc
      end

      def required?
        @required
      end

      def keyword?
        @keyword
      end

      def call(value)
        # TODO: shouldn't to_s `nil`? Or should drop '' afterwards?..
        type.(value)
          .yield_self(&format)
          .yield_self { |val| {field => val.to_s} }
      end
    end
  end
end