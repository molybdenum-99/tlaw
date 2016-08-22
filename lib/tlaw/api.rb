module TLAW
  class API
    class Error < RuntimeError
    end

    attr_reader :endpoints, :namespaces, :initial_param

    def initialize(**param)
      @initial_param = param
      @endpoints = self.class.endpoints.map { |name, klass| [name, klass.new(self)] }.to_h
      @namespaces = self.class.namespaces.map { |name, klass| [name, klass.new(self)] }.to_h
    end

    def inspect
      param = initial_param.reject { |k, v| v.nil? }.map { |k,v| "#{k}: #{v.inspect}" }.join(', ')
      "#<#{self.class.name}(#{param})" +
        (namespaces.empty? ? '' : " namespaces: #{namespaces.keys.join(', ')};") +
        (endpoints.empty? ? '' : " endpoints: #{endpoints.keys.join(', ')};") +
        ' docs: .describe>'
    end

    private

    class << self
      attr_accessor :base_url

      def define(&block)
        DSL::APIWrapper.new(self).define(&block)
      end

      include Shared::ParamHolder
      include Shared::EndpointHolder
      include Shared::NamespaceHolder

      def inspect
        param_def = params.values
          .partition(&:keyword_argument?).reverse.map { |args|
            args.partition(&:required?)
          }.flatten.map(&:generate_definition).join(', ')

        "#<#{self.name} | create: #{self.name}.new(#{param_def}), docs: #{self.name}.describe>"
      end
    end
  end
end
