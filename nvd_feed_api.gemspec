lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nvd_feed_api/version'

Gem::Specification.new do |s|
  s.name          = 'nvd_feed_api'
  s.version       = NvdFeedApi::VERSION
  s.platform      = Gem::Platform::RUBY
  s.date          = '2018-01-06'
  s.summary       = 'API for NVD CVE feeds'
  s.description   = 'A simple API for NVD CVE feeds'
  s.authors       = ['Alexandre ZANNI']
  s.email         = 'alexandre.zanni@europe.com'
  s.homepage      = 'https://noraj.gitlab.io/nvd_api/'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test)/})
  s.require_paths = ['lib']

  s.metadata = {
    'yard.run'          => 'yard',
    'bug_tracker_uri'   => 'https://gitlab.com/noraj/nvd_api/issues',
    'changelog_uri'     => 'https://noraj.gitlab.io/nvd_api/file.CHANGELOG.html',
    'documentation_uri' => 'https://noraj.gitlab.io/nvd_api/',
    'homepage_uri'      => 'https://noraj.gitlab.io/nvd_api/',
    'source_code_uri'   => 'https://gitlab.com/noraj/nvd_api/tree/master',
    'wiki_uri'          => 'https://gitlab.com/noraj/nvd_api/wikis/home'
  }

  s.required_ruby_version = '~> 2.4'

  s.add_dependency('archive-zip', '~> 0.11')
  s.add_dependency('nokogiri', '~> 1.10')
  s.add_dependency('oj', '>= 3.7.8', '<4')

  s.add_development_dependency('bundler', '~> 2.0')
  s.add_development_dependency('commonmarker', '~> 0.18') # for GMF support in YARD
  s.add_development_dependency('github-markup', '~> 3.0') # for GMF support in YARD
  s.add_development_dependency('minitest', '~> 5.11')
  s.add_development_dependency('rake', '~> 12.3')
  s.add_development_dependency('redcarpet', '~> 3.4') # for GMF support in YARD
  s.add_development_dependency('rubocop', '~> 0.63')
  s.add_development_dependency('yard', '~> 0.9')
end
