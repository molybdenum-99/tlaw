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
        Inspect.inspect_endpoint(self)
      end
    end

    attr_reader :url_template

    # Creates endpoint class (or  descendant) instance. Typically, you
    # never use it directly.
    #
    # Params defined in parent namespace are passed here.
    #
    def initialize(parent = nil, **parent_params)
      super

      @url_template = construct_template
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
      api.request(url, self.class.response_processor)
    end

    def_delegators :object_class, :inspect, :describe

    private

    def full_params(**params)
      @parent_params.merge(params.reject { |_, v| v.nil? })
    end

    def construct_template
      url = self.class.base_url
      params = self.class.param_set.all_params.values.map(&:field).map(&:to_s) -
          Addressable::Template.new(url).keys
      joiner = url.include?('?') ? '&' : '?'
      tpl = params.empty? ? url : url + joiner + params.join(',')
      Addressable::Template.new(tpl)
    end

    def construct_url(**params)
      url_params = self.class.param_set.process(**params)
      @url_template
        .expand(url_params).normalize.to_s
        .yield_self(&method(:fix_slash))
    end

    # Fix params substitution: if it was in path part, we shouldn't have escape "/"
    def fix_slash(url)
      url, query = url.split('?', 2)
      url.gsub!('%2F', '/')
      [url, query].compact.join('?')
    end
  end
end
