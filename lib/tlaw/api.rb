module TLAW
  class API < Namespace
    class Error < RuntimeError
    end

    class << self
      def define(&block)
        DSL::APIWrapper.new(self).define(&block)
      end

      def describe
        super.sub(/\A./, '')
      end

      #def inspect
        #param_def = params.values
          #.partition(&:keyword_argument?).reverse.map { |args|
            #args.partition(&:required?)
          #}.flatten.map(&:generate_definition).join(', ')

        #"#<#{self.name} | create: #{self.name}.new(#{param_def}),
        #docs: #{self.name}.describe>"
      #end
    end
  end
end
