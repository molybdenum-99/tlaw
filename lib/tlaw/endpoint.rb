require 'faraday'
require 'faraday_middleware'
require 'addressable/template'
require 'crack'

module TLAW
  # This class does all the hard work: actually calling some HTTP API
  # and processing responses.
  #
  # Each real API endpoint is this class descendant, defining its own
  # params and response processors. On each call small instance of this
  # class is created, {#call}-ed and dies as you don't need it anymore.
  #
  # Typically, you will neither create nor use endpoint descendants or
  # instances directly:
  #
  # * endpoint class definition is performed through {DSL} helpers,
  # * and then, containing namespace obtains `.<current_endpoint_name>()`
  #   method, which is (almost) everything you need to know.
  #
  class Endpoint < APIPath
    class << self
      # Inspects endpoint class prettily.
      #
      # Example:
      #
      # ```ruby
      # some_api.some_namespace.endpoints[:my_endpoint]
      # # => <SomeApi::SomeNamespace::MyEndpoint call-sequence: my_endpoint(param1, param2: nil), docs: .describe>
      # ```
      def inspect
        "#{name || '(unnamed endpoint class)'}(" \
        "call-sequence: #{symbol}(#{param_set.to_code}); docs: .describe)"
      end

      # @private
      def to_code
        "def #{to_method_definition}\n" \
        "  child(:#{symbol}, Endpoint).call(#{param_set.to_hash_code})\n" \
        'end'
      end

      # @private
      def construct_template
        tpl = if query_string_params.empty?
                base_url
              else
                joiner = base_url.include?('?') ? '&' : '?'
                "#{base_url}{#{joiner}#{query_string_params.join(',')}}"
              end
        Addressable::Template.new(tpl)
      end

      # @private
      def parse(body)
        if xml
          Crack::XML.parse(body)
        else
          JSON.parse(body)
        end.yield_self { |response| response_processor.process(response) }
      end

      private

      def query_string_params
        param_set.all_params.values.map(&:field).map(&:to_s) -
          Addressable::Template.new(base_url).keys
      end
    end

    attr_reader :url_template

    # Creates endpoint class (or  descendant) instance. Typically, you
    # never use it directly.
    #
    # Params defined in parent namespace are passed here.
    #
    def initialize(**parent_params)
      super

      @client = Faraday.new do |faraday|
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter Faraday.default_adapter
      end
      @url_template = self.class.construct_template
    end

    # Does the real call to the API, with all params passed to this method
    # and to parent namespace.
    #
    # Typically, you don't use it directly, that's what called when you
    # do `some_namespace.endpoint_name(**params)`.
    #
    # @return [Hash,Array] Parsed, flattened and post-processed response
    #   body.
    def call(**params)
      url = construct_url(**full_params(params))

      @client.get(url).yield_self do |response|
        guard_errors!(response)
        self.class.parse(response.body)
      end
    rescue API::Error
      raise # Not catching in the next block
    rescue StandardError => e
      raise unless url
      raise API::Error, "#{e.class} at #{url}: #{e.message}"
    end

    def_delegators :object_class, :inspect, :describe

    private

    def full_params(**params)
      @parent_params.merge(params.reject { |_, v| v.nil? })
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

    def construct_url(**params)
      url_params = self.class.param_set.process(**params)
      @url_template
        .expand(url_params).normalize.to_s
        .split('?', 2)
        .yield_self { |url, param| [url.gsub('%2F', '/'), param] }
        .compact
        .join('?')
    end
  end
end
