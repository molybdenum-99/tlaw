require './lib/tlaw/version'

Gem::Specification.new do |s|
  s.name     = 'tlaw'
  s.version  = TLAW::VERSION
  s.authors  = ['Victor Shepelev', 'Joel Van Horn']
  s.email    = %w[zverok.offline@gmail.com joel@joelvanhorn.com]
  s.homepage = 'https://github.com/molybdenum-99/tlaw'

  s.summary = 'The Last API Wrapper: Pragmatic API wrapper framework'
  s.description = %q{TLAW is the last (and only) API wrapper framework you'll ever need for accessing APIs in a consistent way (think weather, search, economical indicators, geonames and so on).}
  s.licenses = ['MIT']

  s.files = `git ls-files`.split($RS).reject do |file|
    file =~ /^(?:
    spec\/.*
    |Gemfile
    |Rakefile
    |\.rspec
    |\.gitignore
    |\.rubocop.yml
    |\.travis.yml
    )$/x
  end

  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.3.0'

  s.add_runtime_dependency 'backports'
  s.add_runtime_dependency 'faraday'
  s.add_runtime_dependency 'faraday_middleware'
  s.add_runtime_dependency 'addressable'
  s.add_runtime_dependency 'crack'

  # Managing everything
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubygems-tasks'

  # Testing
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'rspec', '>= 3.5'
  s.add_development_dependency 'rspec-its', '~> 1'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'faker', '>= 1.5'
  s.add_development_dependency 'webmock', '>= 2.1'

  # Documenting
  s.add_development_dependency 'yard', '>= 0.9.5'

  # Used in examples/
  s.add_development_dependency 'dotenv'
  s.add_development_dependency 'geo_coord'
end
