module TLAW
  class Namespace
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

    class << self
      attr_accessor :path, :symbol
      attr_reader :base_url

      def base_url=(url)
        @base_url = url
        endpoints.values.each do |endpoint|
          if endpoint.path && !endpoint.base_url
            endpoint.base_url = base_url + endpoint.path
          end
        end
      end

      def param_set
        @param_set ||= ParamSet.new
      end

      def add_endpoint(endpoint)
        name = endpoint.symbol

        # TODO: validate if it is classifiable
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
  end
end
