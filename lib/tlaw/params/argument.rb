require_relative 'param'

module TLAW
  module Params
    class Argument < Param
      def to_code
        if required?
          name.to_s
        else
          "#{name}=#{default_to_code}"
        end
      end
    end
  end
end
