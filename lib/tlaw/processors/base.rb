module TLAW
  module Processors
    # FIXME: everything is awfully dirty here
    class Base
      attr_reader :processors
      attr_accessor :parent

      def initialize(processors = [])
        @processors = processors
      end

      def all_processors
        [*parent&.all_processors, *@processors]
      end

      def call(response)
        response
          .yield_self(&method(:guard_errors!))
          .yield_self(&method(:parse_response))
          .yield_self(&method(:apply_processors))
      end

      def guard_errors!(response)
        # TODO: follow redirects
        return response if (200...400).cover?(response.status)

        body = JSON.parse(response.body) rescue nil
        message = body && (body['message'] || body['error'])

        fail API::Error,
             ["HTTP #{response.status} at #{response.env[:url]}", message].compact.join(': ')
      end

      def parse_response(response)
        response.body
      end

      def apply_processors(obj)
        all_processors.reduce(obj) { |result, processor| apply(processor, result) }
      end

      def apply(processor, obj)
        processor.call(obj)
      end
    end
  end
end
