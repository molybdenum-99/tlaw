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
      uri = Addressable::URI.new
      uri.query_values = param
      "/#{self.class.path}?" + uri.query
    end

    class << self
      attr_accessor :api, :path

      def add_param(**opts)
      end
    end
  end
end
