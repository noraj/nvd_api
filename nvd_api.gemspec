# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nvd_api/version"

Gem::Specification.new do |s|
    s.name          = 'nvd_api'
    s.version       = Nvd_api::VERSION
    s.platform      = Gem::Platform::RUBY
    s.date          = '2017-09-10'
    s.summary       = "API for NVD CVE"
    s.description   = "A simple API for NVD CVE"
    s.authors       = ["Alexandre ZANNI"]
    s.email         = 'alexandre.zanni@europe.com'
    s.homepage      = 'http://rubygems.org/gems/nvd_api'
    s.license       = 'MIT'

    s.files         = `git ls-files`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.test_files    = s.files.grep(%r{^(test)/})
    s.require_paths = ["lib"]

    s.required_ruby_version = '>= 2.4.0'

    s.add_dependency("nokogiri", "~> 1.8.0")
end
