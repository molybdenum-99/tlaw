$:.unshift 'lib'

require 'rspec/its'
require 'faker'
require 'webmock/rspec'
require 'byebug'

require 'tlaw'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

RSpec::Matchers.define :get_webmock do |url|
  match do |block|
    WebMock.reset!
    stub_request(:get, url).tap { |req|
      req.to_return(@response) if @response
    }
    block.call
    expect(WebMock).to have_requested(:get, url)
  end

  chain :and_return do |response|
    @response = case response
    when String
      {body: response}
    when Hash
      response
    else
      fail "Expected string or Hash of params, got #{response.inspect}"
    end
  end

  supports_block_expectations
end

class String
  # allows to pretty test agains multiline strings:
  #   %Q{
  #     |test
  #     |me
  #   }.unindent # =>
  # "test
  # me"
  def unindent
    gsub(/\n\s+?\|/, "\n")    # for all lines looking like "<spaces>|" -- remove this.
    .gsub(/\|\n/, "\n")       # allow to write trailing space not removed by editor
    .gsub(/\A\n|\n\s+\Z/, '') # remove empty strings before and after
  end
end

class TLAW::Util::Description
  # to make it easily comparable with strings expected.
  def inspect
    to_s.inspect
  end
end
