require 'faraday'
require 'addressable/template'
require 'crack'

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

      def to_tree
        Util::Description.new(
          ".#{to_method_definition} #{construct_template.pattern}"
        )
      end

      def parse(body)
        if xml
          Crack::XML.parse(body)
        else
          JSON.parse(body)
        end.derp { |response| response_processor.process(response) }
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
      url = construct_url(**full_params(params))

      @client.get(url)
             .tap { |response| guard_errors!(response) }
             .derp { |response| self.class.parse(response.body) }
    rescue API::Error
      raise # Not catching in the next block
    rescue => e
      raise unless url
      raise API::Error, "#{e.class} at #{url}: #{e.message}"
    end

    def_delegators :object_class, :inspect, :describe

    private

    def full_params(**params)
      @parent_params.merge(params.reject { |_, v| v.nil? })
    end

    def guard_errors!(response)
      return response if (200...400).cover?(response.status)

      body = JSON.parse(response.body) rescue nil
      message = body && (body['message'] || body['error'])
      puts response.body

      fail API::Error,
           "HTTP #{response.status} at #{response.env[:url]}" +
           (message ? ': ' + message : '')
    end

    def construct_url(**params)
      url_params = self.class.param_set.process(**params)
      @url_template
        .expand(url_params).normalize.to_s
        .split('?', 2).derp { |url, param| [url.gsub('%2F', '/'), param] }
        .compact.join('?')
    end
  end
end
