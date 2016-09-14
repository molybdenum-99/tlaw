module TLAW
  # API is just a top-level {Namespace}.
  #
  # Basically, you start creating your endpoint by descending from API
  # and defining namespaces and endpoints through a {DSL} like this:
  #
  # ```ruby
  # class MyCoolAPI < TLAW::API
  #   define do
  #     base 'http://api.mycool.com'
  #
  #     namespace :awesome do
  #       # ...and so on
  #     end
  #   end
  # end
  # ```
  #
  # And then, you use it:
  #
  # ```ruby
  # api = MyCoolAPI.new
  # api.awesome.cool(param: 'value')
  # ```
  #
  # See {DSL} for explanation of API definition, {Namespace} for explanation
  # of possible usages and {Endpoint} for real calls performing.
  #
  class API < Namespace
    # Thrown when there are an error during call. Contains real URL which
    # was called at the time of an error.
    class Error < RuntimeError
    end

    class << self
      # Runs the {DSL} inside your API wrapper class.
      def define(&block)
        DSL::APIWrapper.new(self).define(&block)
      end

      # Returns detailed description of an API, like this:
      #
      # ```ruby
      # MyCoolAPI.describe
      # # MyCoolAPI.new()
      # #   This is cool API.
      # #
      # #   Namespaces:
      # #   .awesome()
      # #     This is awesome.
      # ```
      #
      def describe(*)
        super.sub(/\A./, '')
      end
    end
  end
end
