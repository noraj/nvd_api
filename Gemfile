# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :runtime, :cli do
  gem 'archive-zip', '0.13.0.pre1'
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
  # commonmarker 2.6.0 currently not supporting on ruby 4.0
  # https://github.com/gjtorikian/commonmarker/issues/427
  gem 'commonmarker', '~> 2.0' # for markdown support in YARD
  gem 'logger', '< 2.0'
  # gem 'yard', ['>= 0.9.27', '< 0.10']
  # yard not supporting recent commonmarker version yet https://github.com/lsegal/yard/issues/1528
  # yard 0.9.38 not supporting ruby 4.0 yet https://github.com/lsegal/yard/issues/1636
  gem 'yard', github: 'ParadoxV5/yard', ref: '9e869c940859570b07b81c5eadd6070e76f6291e', branch: 'commonmarker-1.0'
end
