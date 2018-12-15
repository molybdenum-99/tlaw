module TLAW
  # API is just a top-level {Namespace}.
  #
  # Basically, you start creating your endpoint by descending from API
  # and defining namespaces and endpoints through a {DSL} like this:
  #
  # ```ruby
  # class MyCoolAPI < TLAW::API
  #   define do
  #     base 'http://api.mycool.com'
  #
  #     namespace :awesome do
  #       # ...and so on
  #     end
  #   end
  # end
  # ```
  #
  # And then, you use it:
  #
  # ```ruby
  # api = MyCoolAPI.new
  # api.awesome.cool(param: 'value')
  # ```
  #
  # See {DSL} for explanation of API definition, {Namespace} for explanation
  # of possible usages and {Endpoint} for real calls performing.
  #
  class API < Namespace
    # Thrown when there are an error during call. Contains real URL which
    # was called at the time of an error.
    class Error < RuntimeError
    end

    class << self
      attr_reader :url_template
      private :parent, :parent=

      # Runs the {DSL} inside your API wrapper class.
      def define(**args, &block)
        (args.any? && block) ||
          (args.none? && !block) and
          fail ArgumentError, 'Either keyword arguments or block should be passed'

        if args.any?
          url = args.fetch(:base_url) { fail ArgumentError, 'base_url not specified' }
          args = args.except(:base_url).merge(symbol: nil, path: '')
          super(**args).tap { |cls| cls.url_template = url }
        else
          DSL::APIWrapper.new(self).define(&block)
        end
      end

      # Returns detailed description of an API, like this:
      #
      # ```ruby
      # MyCoolAPI.describe
      # # MyCoolAPI.new()
      # #   This is cool API.
      # #
      # #   Namespaces:
      # #   .awesome()
      # #     This is awesome.
      # ```
      #
      def describe(*)
        super.sub(/\A./, '')
      end

      # @private
      def name_to_call
        "#{name || '(unnamed API class)'}.new"
      end

      protected

      attr_writer :url_template
    end

    private :parent

    def initialize(**params, &block)
      super(nil, **params)

      @client = Faraday.new do |faraday|
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter Faraday.default_adapter
        block&.call(faraday)
      end
    end

    def request(url, **params)
      @client.get(url, **params).yield_self do |response|
        guard_errors!(response)
        parse(response.body)
        # parse(response.body, response_processor)
      end
    rescue API::Error
      raise # Not catching in the next block
    rescue StandardError => e
      raise API::Error, "#{e.class} at #{url}: #{e.message}"
    end

    def guard_errors!(response)
      # TODO: follow redirects
      return response if (200...400).cover?(response.status)

      body = JSON.parse(response.body) rescue nil
      message = body && (body['message'] || body['error'])

      fail API::Error,
           "HTTP #{response.status} at #{response.env[:url]}" +
           (message ? ': ' + message : '')
    end

    def parse(body)
      JSON.parse(body) # FIXME: symbolize_keys?..
    end

    # def parse(body, response_processor)
    #   # TODO: xml is part of "response processing chain"
    #   if self.class.xml
    #     Crack::XML.parse(body)
    #   else
    #     JSON.parse(body)
    #   end.yield_self { |response| response_processor.process(response) }
    # end
  end
end
