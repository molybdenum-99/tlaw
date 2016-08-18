require 'addressable/template'

module TLAW
  class Endpoint
    def initialize(api)
      @api = api
      @template = construct_template
    end

    class << self
      attr_accessor :api, :url, :endpoint_name

      def add_param(name, **opts)
        params[name] = Param.new(name, **opts)
      end

      def params
        @params ||= {}
      end
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

__END__
    def call(*arg, **param)
      #param = validate_param(**param)
      @api.call(construct_url(*arg, **param))
    end

    private

    def construct_url(*arg, **param)
      unless arg.count == template_params.count
        raise RuntimeError, "Expected #{template_params.count} arguments"
      end

      path = if arg.empty?
          self.class.path.dup
        else
          uri_params = template_params.zip(arg).to_h
          self.class.path.gsub(/:([a-z_0-9]+)/) { |name| uri_params[name.tr(':', '').to_sym] }
        end

      namespace = param.delete(:_namespace)


      path = join_uri_parts(namespace, path)
      join_uri_query(path, param)

      #if namespace
        #"/#{namespace}/#{path}?" + uri.query
      #else
        #"/#{path}?" + uri.query
      #end
    end

    def join_uri_parts(*parts)
      parts.compact.map(&:to_s)
        .inject('') {|res, part| part.start_with?('?') ? res + part : [res, part].join('/') }
    end

    def join_uri_query(path, query_params)
      return path if query_params.empty?

      uri = Addressable::URI.new
      uri.query_values = query_params
      query = uri.query

      [path, query].join(path.include?('?') ? '&' : '?')
    end

    def template_params
      @template_params ||= self.class.path.scan(/:([a-z_0-9]+)/).flatten.map(&:to_sym)
    end

    class << self
      attr_accessor :api, :path, :endpoint_name

      def add_param(**opts)
      end
    end
  end
end
