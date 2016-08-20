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

    private

    class << self
      attr_accessor :base_url

      def define(&block)
        DSL::APIWrapper.new(self).define(&block)
      end

      include Shared::ParamHolder
      include Shared::EndpointHolder
      include Shared::NamespaceHolder
    end
  end
end
