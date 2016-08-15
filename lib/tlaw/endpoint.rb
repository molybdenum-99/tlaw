module TLAW
  class Endpoint
    def initialize(api)
      @api = api
    end

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
