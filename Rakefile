# frozen_string_literal: true

require 'rake/testtask'
require 'bundler/gem_tasks'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.warning = false # https://stackoverflow.com/questions/79589272/ruby-bundler-suppress-warning-comming-from-dependencies
end

desc 'Run tests'
task default: :test
