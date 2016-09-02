module TLAW
  class Namespace < APIObject
    class << self
      def base_url=(url)
        @base_url = url

        endpoints.values.each do |endpoint|
          if endpoint.path && !endpoint.base_url
            endpoint.base_url = base_url + endpoint.path
          end
        end
      end

      def add_endpoint(endpoint)
        name = endpoint.symbol

        # TODO:
        # * validate if it is classifiable
        # * provide reasonable defaults for non-classifiable (like :[])
        # * provide additional option for non-default class name
        const_set(Util::camelize(name), endpoint)
        endpoints[name] = endpoint
        endpoint.param_set.parent = param_set
        if endpoint.path && !endpoint.base_url && base_url
          endpoint.base_url = base_url + endpoint.path
        end

        module_eval(endpoint.to_code)
      end

      def endpoints
        @endpoints ||= {}
      end

      def add_namespace(child)
        name = child.symbol

        # TODO: validate if it is classifiable
        const_set(Util::camelize(name), child)
        namespaces[name] = child
        child.param_set.parent = param_set
        if child.path && !child.base_url
          base_url or fail(NameError, 'Current namespace does not define base url')
          child.base_url = base_url + child.path
        end

        define_method(name) { @namespaces[name] }
      end

      def namespaces
        @namespaces ||= {}
      end
    end

    attr_reader :endpoints, :namespaces, :initial_params

    def initialize(**initial_params)
      @initial_params = initial_params # TODO: parent namespace here too

      @namespaces = self.class.namespaces.map { |name, klass| [name, klass.new(initial_params)] }.to_h
      @endpoints = self.class.endpoints.map { |name, klass| [name, klass.new] }.to_h
    end

    def inspect
      "#<#{self.class.name || '(unnamed namespace class)'}" +
        (namespaces.empty? ? '' : " namespaces: #{namespaces.keys.join(', ')};") +
        (endpoints.empty? ? '' : " endpoints: #{endpoints.keys.join(', ')};") +
        ' docs: .describe>'
    end

    def describe
      Util::Description.new(
        self.class.describe + namespaces_description + endpoints_description
      )
    end

    def namespaces_description
      return '' if namespaces.empty?

      "\n\n  Namespaces:\n\n" +
        namespaces.values.map(&:describe)
        .map { |ns| ns.indent('  ') }.join("\n\n") + "\n"
    end

    def endpoints_description
      return '' if endpoints.empty?

      "Endpoints:\n\n" +
        endpoints.values.map(&:describe)
        .map { |ed| ed.indent('  ') }.join("\n\n")
    end
  end
end
