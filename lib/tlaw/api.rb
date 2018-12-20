# frozen_string_literal: true

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
      def define(&block)
        self == API and fail '#define should be called on the descendant of the TLAW::API'
        DSL::ApiBuilder.new(self, &block).finalize
        self
      end

      def setup(base_url: nil, **args)
        if url_template
          base_url and fail ArgumentError, "API's base_url can't be changed on redefinition"
        else
          base_url or fail ArgumentError, "API can't be defined without base_url"
          self.url_template = base_url
        end
        super(symbol: nil, path: '', **args)
      end

      def is_defined? # rubocop:disable Naming/PredicateName
        self < API
      end

      # @method describe
      #   Returns detailed description of an API, like this:
      #
      #   ```ruby
      #   MyCoolAPI.describe
      #   # MyCoolAPI.new()
      #   #   This is cool API.
      #   #
      #   #   Namespaces:
      #   #   .awesome()
      #   #     This is awesome.
      #   ```

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
      @client.get(url, **params).tap(&method(:guard_errors!))
    rescue Error
      raise # Not catching in the next block
    rescue StandardError => e
      raise Error, "#{e.class} at #{url}: #{e.message}"
    end

    def guard_errors!(response)
      # TODO: follow redirects
      return response if (200...400).cover?(response.status)

      fail Error,
           "HTTP #{response.status} at #{response.env[:url]}" +
           extract_message(response.body)&.yield_self { |m| ': ' + m }.to_s
    end

    def extract_message(body)
      # FIXME: well, that's just awful
      data = JSON.parse(body) rescue nil
      return unless data.is_a?(Hash)
      data.values_at('message', 'error').compact.first
    end
  end
end
