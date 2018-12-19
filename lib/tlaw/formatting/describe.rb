# frozen_string_literal: true

module TLAW
  module Formatting
    # @private
    module Describe
      class << self
        def endpoint_class(klass)
          [
            Formatting.call_sequence(klass),
            klass.description&.yield_self { |desc| "\n" + indent(desc, '  ') },
            param_defs(klass.param_defs)
          ].compact.join("\n").yield_self(&Description.method(:new))
        end

        def namespace_class(klass)
          [
            endpoint_class(klass),
            nested(klass.namespaces, 'Namespaces'),
            nested(klass.endpoints, 'Endpoints')
          ].join.yield_self(&Description.method(:new))
        end

        private

        def short(klass)
          descr = klass.description&.yield_self { |d| "\n" + indent(first_para(d), '  ') }
          ".#{Formatting.call_sequence(klass)}#{descr}"
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
          [
            '@param',
            param.name,
            doc_type(param.type)&.yield_self { |t| "[#{t}]" },
            param.description,
            possible_values(param.type),
            param.default&.yield_self { |d| "(default = #{d.inspect})" }
          ].compact.join(' ').gsub(/ +\n/, "\n")
        end

        def possible_values(type)
          return unless type.respond_to?(:possible_values)
          "\n  Possible values: #{type.possible_values}"
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
end
