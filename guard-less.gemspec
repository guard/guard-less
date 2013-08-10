# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'guard/less/version'

Gem::Specification.new do |s|
  s.name        = 'guard-less'
  s.version     = Guard::LessVersion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Brendan Erwin']
  s.email       = ['brendanjerwin@gmail.com']
  s.homepage    = 'https://github.com/guard/guard-less'
  s.summary     = 'Guard gem for Less'
  s.description = 'Guard::Less automatically compiles less (like lessc --watch)'
  
  s.required_rubygems_version = '>= 1.3.6'
  # s.rubyforge_project         = 'guard-less'
  
  s.add_dependency 'guard', '>= 0.2.2'
  s.add_dependency 'less',  '~> 2.3.1'

  s.add_development_dependency 'bundler',     '~> 1.0'
  s.add_development_dependency 'fakefs',      '~> 0.3'
  s.add_development_dependency 'guard-rspec', '~> 0.4'
  s.add_development_dependency 'rspec',       '~> 2.6'
  
  s.files        = Dir.glob('{lib}/**/*') + %w[README.md]
  s.require_path = 'lib'
end
