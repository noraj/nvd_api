require_relative 'lib/nvd_feed_api/version'

Gem::Specification.new do |s|
  s.name          = 'nvd_feed_api'
  s.version       = NvdFeedApi::VERSION
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'API for NVD CVE feeds'
  s.description   = 'A simple API for NVD CVE feeds'
  s.authors       = ['Alexandre ZANNI']
  s.email         = 'alexandre.zanni@europe.com'
  s.homepage      = 'https://noraj.gitlab.io/nvd_api/'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.metadata = {
    'yard.run'              => 'yard',
    'bug_tracker_uri'       => 'https://gitlab.com/noraj/nvd_api/issues',
    'changelog_uri'         => 'https://noraj.gitlab.io/nvd_api/file.CHANGELOG.html',
    'documentation_uri'     => 'https://noraj.gitlab.io/nvd_api/',
    'homepage_uri'          => 'https://noraj.gitlab.io/nvd_api/',
    'source_code_uri'       => 'https://gitlab.com/noraj/nvd_api/tree/master',
    'wiki_uri'              => 'https://gitlab.com/noraj/nvd_api/wikis/home',
    'funding_uri'           => 'https://github.com/sponsors/noraj',
    'rubygems_mfa_required' => 'true'
  }

  s.required_ruby_version = ['>= 2.7.0', '< 4.0']

  s.add_dependency('archive-zip', '~> 0.11')
  s.add_dependency('nokogiri', '~> 1.11')
  s.add_dependency('oj', '>= 3.7.8', '<4')
end
