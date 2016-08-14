require 'open-uri'
require 'json'
require 'addressable'

class Object
  def derp
    yield self
  end
end

module TLAW
  class API
    attr_reader :endpoints

    def initialize(**param)
      @initial_param = param
      @endpoints = self.class.endpoints.map { |name, klass| [name, klass.new(self)] }.to_h
    end

    def call(path)
      open(self.class.base_url + '/' + path).read
        .derp { |response| JSON.parse(response) }
        .derp(&Util.method(:flatten_hashes))
    end

    private

    class << self
      attr_accessor :base_url

      def define(&block)
        DSL::APIWrapper.new(self).define(&block)
      end

      def add_param(**opts)
      end

      def add_endpoint(name, endpoint)
        # TODO: validate a) if it already exists b) if it is classifiable
        const_set(Util::camelize(name), endpoint)
        endpoints[name] = endpoint

        define_method(name) { |*arg, **param|
          @endpoints[name].call(*arg, **@initial_param.merge(param))
        }
      end

      def endpoints
        @endpoints ||= {}
      end
    end
  end

  module Util
    module_function

    def camelize(string)
      string.to_s
        .sub(/^[a-z\d]*/) { |l| l.capitalize }
        .gsub(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
    end

    def flatten_hashes(val)
      case val
      when Array
        val.map { |e| flatten_hashes(e) }
      when Hash
        flatten_hash(val)
      else
        val
      end
    end

    def flatten_hash(hash)
      hash.map { |k, v|
        if v.is_a?(Hash)
          flatten_hash(v).map { |k1, v1| ["#{k}.#{k1}", v1] }
        else
          [[k, flatten_hashes(v)]]
        end
      }.flatten(1).to_h
    end
  end

  class Endpoint
    def initialize(api)
      @api = api
    end

    def call(*arg, **param)
      #unless arg.empty?
      #end

      #param = validate_param(**param)
      @api.call(construct_url(**param))
    end

    private

    def construct_url(**param)
      uri = Addressable::URI.new
      uri.query_values = param
      "/#{self.class.path}?" + uri.query
    end

    class << self
      attr_accessor :api, :path

      def add_param(**opts)
      end
    end
  end

  module DSL
    class APIWrapper
      def initialize(api)
        @api = api
      end

      def define(&block)
        instance_eval(&block)
      end

      def base(url)
        @api.__send__(:base_url=, url)
      end

      def param(name, type, **opts)
        @api.__send__(:add_param, **opts.merge(name: name, type: type))
      end

      def endpoint(path, **opts, &block)
        Class.new(Endpoint).tap do |ep|
          ep.api = @api
          ep.path = path
          EndpointWrapper.new(ep).define(&block)
          @api.__send__(:add_endpoint, path, ep)
        end
      end
    end

    class EndpointWrapper
      def initialize(endpoint)
        @endpoint = endpoint
      end

      def define(&block)
        instance_eval(&block)
      end

      def param(name, type, **opts)
        @endpoint.__send__(:add_param, **opts.merge(name: name, type: type))
      end
    end
  end
end

