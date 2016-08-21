require 'faraday'
require 'addressable/template'

module TLAW
  class Endpoint
    def initialize(api)
      @api = api
      @client = Faraday.new
      @template = construct_template
    end

    class << self
      attr_accessor :api, :url, :endpoint_name

      include Shared::ParamHolder

      def generate_definition
        arg_def = own_params
          .partition(&:keyword_argument?).reverse.map { |args|
            args.partition(&:required?)
          }.flatten.map(&:generate_definition).join(', ')

        "def #{endpoint_name}(#{arg_def})\n" +
        "  param = initial_param.merge(#{own_params.map(&:name).map { |n| "#{n}: #{n}" }.join(', ')})\n" +
        "  endpoints[:#{endpoint_name}].call(**param)\n" +
        "end"
      end

      private

      def own_params
        params.values.reject(&:common?)
      end
    end

    def call(**params)
      url = construct_url(**params)

      @client.get(construct_url(**params))
        .tap { |response| guard_errors!(response) }
        .derp { |response| JSON.parse(response.body) }
        .derp(&Util.method(:flatten_hash))
    rescue API::Error
      raise
    rescue => e
      fail API::Error, "#{e.class} at #{url}: #{e.message}"
    end

    private

    def guard_errors!(response)
      return response if (200...400).include?(response.status)

      p response.body
      body = JSON.parse(response.body) rescue nil
      message = body && (body['message'] || body['error'])

      if message
        fail API::Error, "HTTP #{response.status} at #{response.env[:url]}: #{message}"
      else
        fail API::Error, "HTTP #{response.status} at #{response.env[:url]}"
      end
    end

    def construct_template
      t = Addressable::Template.new(self.class.url)
      query_params = self.class.params.reject { |k, v| t.keys.include?(k.to_s) }

      tpl = if query_params.empty?
          self.class.url
        else
          joiner = self.class.url.include?('?') ? '&' : '?'

          self.class.url + '{' + joiner + query_params.keys.join(',') + '}'
        end
      Addressable::Template.new(tpl)
    end

    def construct_url(**params)
      url_params = self.class.params
        .map { |name, dfn| [name, dfn, params[name]] }
        .reject { |*, val| val.nil? }
        .map { |name, dfn, val| [name, dfn.convert_and_format(val)] }
        .to_h
      @template.expand(url_params).to_s
    end
  end
end
