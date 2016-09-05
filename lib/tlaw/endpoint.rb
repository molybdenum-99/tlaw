require 'faraday'
require 'addressable/template'
require 'forwardable'

module TLAW
  class Endpoint < APIObject
    class << self
      def to_code
        "def #{to_method_definition}\n" \
        "  child(:#{symbol}, Endpoint).call({#{param_set.to_hash_code}})\n" \
        'end'
      end

      def inspect
        "#<#{name || '(unnamed endpoint class)'}:" \
        " call-sequence: #{symbol}(#{param_set.to_code}); docs: .describe>"
      end

      def construct_template
        tpl = if query_string_params.empty?
                base_url
              else
                joiner = base_url.include?('?') ? '&' : '?'
                "#{base_url}{#{joiner}#{query_string_params.join(',')}}"
              end
        Addressable::Template.new(tpl)
      end

      private

      def query_string_params
        param_set.all_params.values.map(&:field).map(&:to_s) -
          Addressable::Template.new(base_url).keys
      end
    end

    attr_reader :url_template

    def initialize(**parent_params)
      super

      @client = Faraday.new
      @url_template = self.class.construct_template
    end

    def call(**params)
      url = construct_url(**@parent_params.merge(params))

      @client.get(url)
             .tap { |response| guard_errors!(response) }
             .derp { |response| JSON.parse(response.body) }
             .derp { |response|
               self.class.response_processor.process(response)
             }
    rescue API::Error
      raise # Not catching in the next block
    rescue => e
      raise unless url
      raise API::Error, "#{e.class} at #{url}: #{e.message}"
    end

    extend Forwardable

    def_delegators :self_class, :inspect, :describe

    private

    def self_class
      self.class
    end

    def guard_errors!(response)
      return response if (200...400).cover?(response.status)

      body = JSON.parse(response.body) rescue nil
      message = body && (body['message'] || body['error'])

      fail API::Error,
           "HTTP #{response.status} at #{response.env[:url]}" +
           (message ? ': ' + message : '')
    end

    def construct_url(**params)
      url_params = self.class.param_set.process(**params)
      @url_template.expand(url_params).to_s
    end
  end
end
