require_relative 'base'

module TLAW
  module Params
    class Argument < Base
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
