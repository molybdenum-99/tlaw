require 'rspec/its'
require 'faker'
require 'webmock/rspec'
# require 'byebug'
require 'saharspec'

require 'simplecov'
require 'coveralls'

Coveralls.wear!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]
)

$LOAD_PATH.unshift 'lib'

require 'tlaw'

RSpec.configure do |config|
  config.disable_monkey_patching!
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
    @response =
      case response
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
    gsub(/\n\s+?\|/, "\n")      # for all lines looking like "<spaces>|" -- remove this.
      .gsub(/\|\n/, "\n")       # allow to write trailing space not removed by editor
      .gsub(/\A\n|\n\s+\Z/, '') # remove empty strings before and after
  end
end

class TLAW::Util::Description # rubocop:disable Style/ClassAndModuleChildren
  # to make it easily comparable with strings expected.
  def inspect
    to_s.inspect
  end
end

RSpec::Matchers.define :not_have_key do |key|
  match do |actual|
    expect(actual).not_to be_key(key)
  end
end

RSpec::Matchers.define :define_constant do |name|
  match do |block|
    if const_exists?(name)
      @already_exists = true
      break false
    end
    block.call
    const_exists?(name)
  end

  description do
    "expected block to create constant #{name}"
  end

  failure_message do
    if @already_exists
      "#{description}, but it is already existing"
    else
      last_found = @path[0...@modules.count - 1].join('::')
      not_found = @path[@modules.count - 1] # FIXME: slice or something, I forgot :(
      problem = @modules.last.respond_to?(:const_defined?) ? "does not define #{not_found}" : "is not a module"
      "#{description}, but #{last_found} #{problem}"
    end
  end

  supports_block_expectations

  def const_exists?(name)
    @path = name.split('::').drop_while(&:empty?)
    @modules = @path.reduce([Kernel]) { |(*prevs, cur), name|
      break [*prevs, cur] unless cur.respond_to?(:const_defined?) && cur.const_defined?(name)
      [*prevs, cur, cur.const_get(name)]
    }
    @modules.count - 1 == @path.size
  end
end

def param(name, **arg)
  TLAW::Param.new(name: name, **arg)
end

