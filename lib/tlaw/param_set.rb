module TLAW
  class ParamSet
    attr_accessor :parent

    def initialize
      @params = {}
    end

    def add(name, **opts)
      if @params[name]
        @params[name].update(**opts)
      else
        @params[name] = Param.new(name, **opts)
      end
    end

    def [](name)
      @params[name]
    end

    def to_a
      @params.values
    end

    def to_h
      @params
    end

    def names
      @params.keys
    end

    def empty?
      @params.empty?
    end

    def to_code
      ordered.map(&:to_code).join(', ')
    end

    def describe
      Util::Description.new(ordered.map(&:describe).join("\n"))
    end

    def process(**input)
      (input.keys - all_params.keys).tap { |unknown|
        unknown.empty? or raise(ArgumentError, "Unknown parameters: #{unknown.join(', ')}")
      }
      all_params
        .map { |name, dfn| [name, dfn, input[name]] }
        .each { |name, dfn, val| dfn.required? && val.nil? and raise(ArgumentError, "Required parameter #{name} is missing") }
        .reject { |*, val| val.nil? }
        .map { |name, dfn, val| [name, dfn.convert_and_format(val)] }
        .to_h
    end

    def all_params
      (@parent ? @parent.all_params : {}).merge(@params)
    end

    private

    def ordered
      @params.values
        .partition(&:keyword_argument?).reverse.map { |args|
          args.partition(&:required?)
        }.flatten
    end
  end
end
