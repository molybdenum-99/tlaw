# frozen_string_literal: true

module TLAW
  # API is a main TLAW class (and the only one you need to use directly).
  #
  # Basically, you start creating your definition by descending from API and defining namespaces and
  # endpoints through a {DSL} like this:
  #
  # ```ruby
  # class SomeImagesAPI < TLAW::API
  #   define do
  #     base 'http://api.mycool.com'
  #
  #     namespace :gifs do
  #       endpoint :search do
  #         param :query
  #       end
  #       # ...and so on
  #     end
  #   end
  # end
  # ```
  #
  # And then, you use it:
  #
  # ```ruby
  # api = SomeImagesAPI.new
  # api.gifs.search(query: 'butterfly')
  # ```
  #
  # See {DSL} for detailed information of API definition, and {Namespace} for explanation about
  # dynamically generated methods ({API} is also an instance of a {Namespace}).
  #
  class API < Namespace
    # Thrown when there are an error during call. Contains real URL which was called at the time of
    # an error.
    class Error < RuntimeError
    end

    class << self
      # @private
      attr_reader :url_template

      # Runs the {DSL} inside your API wrapper class.
      def define(&block)
        self == API and fail '#define should be called on the descendant of the TLAW::API'
        DSL::ApiBuilder.new(self, &block).finalize
        self
      end

      # @private
      def setup(base_url: nil, **args)
        if url_template
          base_url and fail ArgumentError, "API's base_url can't be changed on redefinition"
        else
          base_url or fail ArgumentError, "API can't be defined without base_url"
          self.url_template = base_url
        end
        super(symbol: nil, path: '', **args)
      end

      # @private
      def is_defined? # rubocop:disable Naming/PredicateName
        self < API
      end

      protected

      attr_writer :url_template

      private :parent, :parent=
    end

    private :parent

    # Create an instance of your API descendant.
    # Params to pass here correspond to `param`s defined at top level of the DSL, e.g.
    #
    # ```ruby
    # # if you defined your API like this...
    # class MyAPI < TLAW::API
    #   define do
    #     param :api_key
    #     # ....
    #   end
    # end
    #
    # # the instance should be created like this:
    # api = MyAPI.new(api_key: '<some-api-key>')
    # ```
    #
    # If the block is passed, it is called with an instance of
    # [Faraday::Connection](https://www.rubydoc.info/gems/faraday/Faraday/Connection) object which
    # would be used for API requests, allowing to set up some connection configuration:
    #
    # ```ruby
    # api = MyAPI.new(api_key: '<some-api-key>') { |conn| conn.basic_auth 'login', 'pass' }
    # ```
    #
    # @yield [Faraday::Connection]
    def initialize(**params, &block)
      super(nil, **params)

      @client = Faraday.new do |faraday|
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter Faraday.default_adapter
        block&.call(faraday)
      end
    end

    # @private
    def request(url, **params)
      @client.get(url, **params).tap(&method(:guard_errors!))
    rescue Error
      raise # Not catching in the next block
    rescue StandardError => e
      raise Error, "#{e.class} at #{url}: #{e.message}"
    end

    private

    def guard_errors!(response)
      # TODO: follow redirects
      return response if (200...400).cover?(response.status)

      fail Error,
           "HTTP #{response.status} at #{response.env[:url]}" +
           extract_message(response.body)&.yield_self { |m| ': ' + m }.to_s
    end

    def extract_message(body)
      # FIXME: well, that's just awful
      # ...minimal is at least extract *_message key (TMDB has status_message, for ex.)
      data = JSON.parse(body) rescue nil
      return body unless data.is_a?(Hash)

      data.values_at('message', 'error').compact.first || body
    end
  end
end
