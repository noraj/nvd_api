source 'https://rubygems.org'

gemspec

group :runtime, :cli do
  gem 'archive-zip', '~> 0.11'
  gem 'nokogiri', '~> 1.11'
  gem 'oj', '>= 3.7.8', '<4'
end

group :development, :install do
  gem 'bundler', '~> 2.1'
end

group :development, :test do
  gem 'minitest', '~> 5.12'
  gem 'rake', '~> 13.0'
end

group :development, :lint do
  gem 'rubocop', '~> 1.23'
  gem 'rubocop-minitest', '~> 0.20.1'
end

group :development, :docs do
  gem 'commonmarker', '~> 0.21' # for markdown support in YARD
  gem 'yard', ['>= 0.9.27', '< 0.10']
end
