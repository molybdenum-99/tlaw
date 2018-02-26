require_relative 'param'

module TLAW
  module Params
    class Keyword < Param
      def keyword?
        true
      end

      def to_code
        if required?
          "#{name}:"
        else
          "#{name}: #{default_to_code}"
        end
      end
    end
  end
end
