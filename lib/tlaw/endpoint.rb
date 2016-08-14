module TLAW
  class Endpoint
    def initialize(api)
      @api = api
    end

    def call(*arg, **param)
      #unless arg.empty?
      #end

      #param = validate_param(**param)
      @api.call(construct_url(**param))
    end

    private

    def construct_url(**param)
      namespace = param.delete(:_namespace)

      uri = Addressable::URI.new
      uri.query_values = param


      if namespace
        "/#{namespace}/#{self.class.path}?" + uri.query
      else
        "/#{self.class.path}?" + uri.query
      end
    end

    class << self
      attr_accessor :api, :path, :endpoint_name

      def add_param(**opts)
      end
    end
  end
end
