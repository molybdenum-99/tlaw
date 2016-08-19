require 'addressable/template'

module TLAW
  class Endpoint
    def initialize(api)
      @api = api
      @template = construct_template
    end

    class << self
      attr_accessor :api, :url, :endpoint_name

      include Shared::ParamHolder
    end

    def call(**params)
      open(construct_url(**params)).read
        .derp { |response| JSON.parse(response) }
        .derp(&Util.method(:flatten_hashes))
    end

    private

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
