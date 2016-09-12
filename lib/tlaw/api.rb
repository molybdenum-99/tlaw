module TLAW
  class API < Namespace
    class Error < RuntimeError
    end

    class << self
      def define(&block)
        DSL::APIWrapper.new(self).define(&block)
      end

      def describe(*)
        super.sub(/\A./, '')
      end
    end
  end
end
