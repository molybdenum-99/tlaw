require_relative 'base'
require 'json'
require 'crack'

module TLAW
  module Processors
    class ResponseProcessor < Base
      def parse_response(response)
        if response.headers['Content-Type'] =~ /xml/
          Crack::XML.parse(response.body)
        else
          JSON.parse(response.body)
        end
      end
    end
  end
end
