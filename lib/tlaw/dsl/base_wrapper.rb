require_relative 'transforms'

module TLAW
  module DSL
    class BaseWrapper
      def initialize(object)
        @object = object
      end

      def define(&block)
        instance_eval(&block)
      end

      def description(text)
        # first, remove spaces at a beginning of each line
        # then, remove empty lines before and after docs block
        @object.description =
          text
          .gsub(/^[ \t]+/, '')
          .gsub(/\A\n|\n\s*\Z/, '')
      end

      alias_method :desc, :description

      def docs(link)
        @object.docs_link = link
      end

      def param(name, type = nil, **opts)
        @object.param_set.add(name, **opts.merge(type: type))
      end

      def response_processor(processor)
        @object.response_processor = processor
      end

      def transform(key = nil, replace: false, &block)
        @object.response_processor.processors << Transforms.build(key, replace: replace, &block)
      end

      def transform_item(key, subkey = nil, &block)
        @object.response_processor.processors << Transforms::Items.new(key, subkey, &block)
      end

      def transform_items(key, &block)
        @object.response_processor.processors.concat Transforms::ItemsBatch.batch(key, &block)
      end
    end
  end
end
