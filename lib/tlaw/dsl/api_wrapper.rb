require_relative 'namespace_wrapper'

module TLAW
  module DSL
    class APIWrapper < NamespaceWrapper
      def base(url)
        @object.base_url = url
      end
    end
  end
end
