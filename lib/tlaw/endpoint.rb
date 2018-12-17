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
      # some_api.some_namespace.endpoint(:my_endpoint)
      # # => <SomeApi::SomeNamespace::MyEndpoint call-sequence: my_endpoint(param1, param2: nil), docs: .describe>
      # ```
      def inspect
        return super unless is_defined?
        Formatting::Inspect.endpoint_class(self)
      end
    end

    attr_reader :url, :request_params

    # Creates endpoint class (or  descendant) instance. Typically, you
    # never use it directly.
    #
    # Params defined in parent namespace are passed here.
    #
    def initialize(parent, **params)
      super

      template = Addressable::Template.new(url_template)

      @url = template.expand(**prepared_params).to_s.yield_self(&method(:fix_slash))
      url_keys = template.keys.map(&:to_sym)
      @request_params = prepared_params.reject { |k, | url_keys.include?(k) }
    end

    # Does the real call to the API, with all params passed to this method
    # and to parent namespace.
    #
    # Typically, you don't use it directly, that's what called when you
    # do `some_namespace.endpoint_name(**params)`.
    #
    # @return [Hash,Array] Parsed, flattened and post-processed response
    #   body.
    def call
      api.request(url, **request_params) #, response_processor)
    end

    def inspect
      Formatting::Inspect.endpoint(self)
    end

    def_delegators :self_class, :describe

    private

    def_delegators :self_class, :url_template

    # Fix params substitution: if it was in path part, we shouldn't have escaped "/"
    # E.g. for template "http://google.com/{foo}/bar", and foo="some/path", Addressable would
    # produce "http://google.com/some%2fpath/bar", but we want "http://google.com/some/path/bar"
    def fix_slash(url)
      url, query = url.split('?', 2)
      url.gsub!('%2F', '/')
      [url, query].compact.join('?')
    end
  end
end
