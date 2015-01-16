# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)
require 'guard/less/version'

Gem::Specification.new do |s|
  s.name        = 'guard-less'
  s.version     = Guard::LessVersion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  s.authors     = ['Brendan Erwin']
  s.email       = ['brendanjerwin@gmail.com']
  s.homepage    = 'https://rubygems.org/gems/guard-less'
  s.summary     = 'Guard gem for Less'
  s.description = 'Guard::Less automatically compiles less (like lessc --watch)'

  s.required_ruby_version = '>= 1.9.2'

  s.add_runtime_dependency 'guard', '~> 2.0'
  s.add_runtime_dependency 'guard-compat', '~> 1.2'
  s.add_runtime_dependency 'less',  '~> 2.3'

  s.add_development_dependency 'bundler'

  s.files        = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.require_path = 'lib'
end
