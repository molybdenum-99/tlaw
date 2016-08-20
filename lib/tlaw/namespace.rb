module TLAW
  class Namespace
    attr_reader :endpoints, :initial_param

    def initialize(api)
      @api = api
      @initial_param = api.initial_param # TODO: could add param at namespace call?..

      # TODO: responsibility of endpoints_holder?
      @endpoints = self.class.endpoints.map { |name, klass| [name, klass.new(api)] }.to_h
    end

    class << self
      attr_accessor :api
      attr_accessor :base_url
      attr_accessor :namespace_name

      include Shared::ParamHolder
      include Shared::EndpointHolder
      include Shared::NamespaceHolder
    end
  end
end
