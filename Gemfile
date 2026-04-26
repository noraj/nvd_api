# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :runtime, :cli do
  gem 'archive-zip', '0.13.1'
  gem 'nokogiri', '~> 1.11'
  gem 'oj', '>= 3.7.8', '<4'
end

group :development, :install do
  gem 'bundler', '~> 4.0'
end

group :development, :test do
  gem 'minitest', '~> 6.0'
  gem 'rake', '~> 13.2'
end

group :development, :lint do
  gem 'rubocop', '~> 1.71'
  gem 'rubocop-minitest', '~> 0.36'
end

group :development, :docs do
  gem 'commonmarker', '~> 2.8'
  gem 'irb' # to supress warning because using @overload from yard https://github.com/lsegal/yard/pull/1643#issuecomment-4322721189
  gem 'yard', ['>= 0.9.43', '< 0.10']
end
