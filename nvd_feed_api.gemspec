lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nvd_feed_api/version'

Gem::Specification.new do |s|
  s.name          = 'nvd_feed_api'
  s.version       = NvdFeedApi::VERSION
  s.platform      = Gem::Platform::RUBY
  s.date          = '2017-09-10'
  s.summary       = 'API for NVD CVE feeds'
  s.description   = 'A simple API for NVD CVE feeds'
  s.authors       = ['Alexandre ZANNI']
  s.email         = 'alexandre.zanni@europe.com'
  s.homepage      = 'http://rubygems.org/gems/nvd_feed_api'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test)/})
  s.require_paths = ['lib']

  s.metadata = {
    'yard.run'          => 'yard',
    'bug_tracker_uri'   => 'https://gitlab.com/noraj/nvd_api/issues',
    'changelog_uri'     => '',
    'documentation_uri' => '',
    'homepage_uri'      => '',
    'source_code_uri'   => 'https://gitlab.com/noraj/nvd_api/tree/master',
    'wiki_uri'          => 'https://gitlab.com/noraj/nvd_api/wikis/home'
  }

  s.required_ruby_version = '~> 2.4'

  s.add_dependency('archive-zip', '~> 0.10')
  s.add_dependency('nokogiri', '~> 1.8')
  s.add_dependency('oj', '~> 3.3')

  s.add_development_dependency('commonmarker', '~> 0.17') # for GMF support in YARD
  s.add_development_dependency('github-markup', '~> 1.6') # for GMF support in YARD
  s.add_development_dependency('minitest', '~> 5.10')
  s.add_development_dependency('rubocop', '~> 0.51')
  s.add_development_dependency('yard', '~> 0.9')
end
