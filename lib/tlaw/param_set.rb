module TLAW
  class ParamSet
    attr_accessor :parent

    def initialize
      @params = {}
    end

    def add(name, **opts)
      # Not updating parent param, just make sure it exists
      return if @parent && @parent.all_params[name]

      @params[name] =
        if @params[name]
          @params[name].merge(**opts)
        else
          Param.make(name, **opts)
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
      @params.empty? && (!@parent || @parent.empty?)
    end

    def to_code
      ordered.map(&:to_code).join(', ')
    end

    def to_hash_code(values = nil)
      if values
        names.map { |n| "#{n}: #{values[n].inspect}" }.join(', ')
      else
        names.map { |n| "#{n}: #{n}" }.join(', ')
      end
    end

    def describe
      Util::Description.new(ordered.map(&:describe).join("\n"))
    end

    def process(**input)
      validate_unknown(input)

      all_params
        .map { |name, dfn| [name, dfn, input[name]] }
        .tap(&method(:validate_required))
        .reject { |*, val| val.nil? }
        .map { |_name, dfn, val| [dfn.field, dfn.convert_and_format(val)] }
        .to_h
    end

    def all_params
      (@parent ? @parent.all_params : {}).merge(@params)
    end

    def inspect
      "#<#{self.class.name} #{names.join(', ')}"\
        "#{" (parent=#{parent.inspect})" if parent && !parent.empty?}>"
    end

    alias_method :to_s, :inspect

    private

    def validate_unknown(input)
      (input.keys - all_params.keys).tap { |unknown|
        unknown.empty? or
          fail(ArgumentError, "Unknown parameters: #{unknown.join(', ')}")
      }
    end

    def validate_required(definitions_and_params)
      definitions_and_params.each do |name, dfn, val|
        dfn.required? && val.nil? and
          fail ArgumentError, "Required parameter #{name} is missing"
      end
    end

    def ordered
      @params.values
             .partition(&:keyword_argument?).reverse.map { |args|
               args.partition(&:required?)
             }.flatten
    end
  end
end
