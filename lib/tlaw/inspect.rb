module TLAW
  module Inspect
    def inspect_endpoint(klass)
      "#{klass.name || '(unnamed endpoint class)'}(" \
        "call-sequence: #{call_sequence(klass)}; docs: .describe)"
    end

    def inspect_namespace(klass, param_values = nil)
      "#{klass.name || '(unnamed namespace class)'}(" \
        "call-sequence: #{call_sequence(klass, param_values)};" +
        inspect_namespaces(klass.namespaces) +
        inspect_endpoints(klass.namespaces) +
        ' docs: .describe)'
    end

    def describe(klass, param_values = nil)
      ".#{call_sequence(klass, param_values)}"
        .+(description ? "\n" + description.indent('  ') + "\n" : '')
        .+(param_set.empty? ? '' : "\n" + describe_params(param_set).indent('  '))
        .yield_self(&Util::Description.method(:new))
    end

    def describe_namespace(klass)
      describe(klass) +
        describe_namespaces(klass.namespaces) +
        describe_endpoints(klass.endpoints)
    end

    def call_sequence(klass)
      params = params_to_ruby(klass.param_set)
      params.empty? ? klass.name_to_call.to_s : "#{klass.name_to_call}(#{params})"
    end

    def describe_params(param_set)
      Util::Description.new(param_set.ordered.map(&method(:describe_param)).join("\n"))
    end

    def describe_param(param)
      [
        '@param',
        param.name,
        param.doc_type&.yield_self { |t| "[#{t}]" },
        param.description,
        ("\n  Possible values: #{param.type.possible_values}" if param.type.respond_to?(:possible_values)),
        param.default&.yield_self { |d| "(default = #{d.inspect})" }
      ]
        .compact
        .join(' ')
        .yield_self(&Util::Description.method(:new))
    end

    def params_to_ruby(param_set)
      param_set.ordered.map(&method(:param_to_ruby)).join(', ')
    end

    def param_to_ruby(param)
      name = param.name.to_s
      default = param.default.inspect

      case [param.class, param.required?]
      when [Params::Argument, true]
        name
      when [Params::Argument, false]
        "#{name}=#{default}"
      when [Params::Keyword, true]
        "#{name}:"
      when [Params::Keyword, false]
        "#{name}: #{default}"
      end
    end

    private


    def describe_short(klass)
      ".#{call_sequence(klass)}"
        .+(klass.description&.yield_self { |d| "\n" + first_para(d).indent('  ') } || '')
        .yield_self(&Util::Description.method(:new))
    end

    def inspect_namespaces(namespaces)
      return '' if namespaces.empty?
      " namespaces: #{namespaces.map(&:symbol).join(', ')};"
    end

    def inspect_endpoints(endpoints)
      return '' if endpoints.empty?
      " endpoints: #{endpoints.map(&:symbol).join(', ')};"
    end

    def describe_namespaces(namespaces)
      return '' if namespaces.empty?

      "\n\n  Namespaces:\n\n" + children_description(namespaces)
    end

    def describe_endpoints(endpoints)
      return '' if endpoints.empty?

      "\n\n  Endpoints:\n\n" + children_description(endpoints)
    end

    def children_description(children)
      children.map(&method(:describe_short))
              .map { |cd| cd.indent('  ') }
              .join("\n\n")
    end

    def first_para(str)
      str.split("\n\n").first
    end
  end
end