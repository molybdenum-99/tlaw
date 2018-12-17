module TLAW
  module Formatting
    module Describe
      module_function

      def endpoint_class(klass)
        [
          Formatting.call_sequence(klass),
          klass.description&.yield_self { |desc| "\n" + indent(desc, '  ') },
          param_defs(klass.param_defs)
        ].compact.join("\n").yield_self(&Util::Description.method(:new))
      end

      def namespace_class(klass)
        [
          endpoint_class(klass),
          nested(klass.namespaces, 'Namespaces'),
          nested(klass.endpoints, 'Endpoints')
        ].join.yield_self(&Util::Description.method(:new))
      end

      def short(klass)
        Formatting.call_sequence(klass)
          .+(klass.description&.yield_self { |d| "\n" + indent(first_para(d), '  ') } || '')
      end

      def describe_namespaces(namespaces)
        return '' if namespaces.empty?

        "\n\n  Namespaces:\n\n" + children_description(namespaces)
      end

      def describe_endpoints(endpoints)
        return '' if endpoints.empty?

        "\n\n  Endpoints:\n\n" + children_description(endpoints)
      end

      def nested(klasses, title)
        return '' if klasses.empty?

        "\n\n  #{title}:\n\n" +
          klasses.map(&method(:short))
                  .map { |cd| indent(cd, '  ') }
                  .join("\n\n")
      end

      def param_defs(defs)
        return nil if defs.empty?
        defs
          .map(&method(:param_def))
          .join("\n")
          .yield_self { |s| "\n" + indent(s, '  ') }
      end

      def param_def(param)
        res = ['@param', param.name]
        res << doc_type(param.type)&.yield_self { |t| "[#{t}]" }
        res << param.description
        if param.type.respond_to?(:possible_values)
          res << "\n  Possible values: #{param.type.possible_values}"
        end
        res << param.default&.yield_self { |d| "(default = #{d.inspect})" }

        res.compact.join(' ').gsub(/ +\n/, "\n")
      end

      def doc_type(type)
        case type
        when Param::ClassType
          type.type.name
        when Param::DuckType
          "##{type.type}"
        end
      end

      def first_para(str)
        str.split("\n\n").first
      end

      def indent(str, indentation = '  ')
        str.gsub(/(\A|\n)/, '\1' + indentation)
      end
    end
  end
end