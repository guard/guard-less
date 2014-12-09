source 'https://rubygems.org'

gemspec

gem 'rake'

group :development do
  gem 'ruby_gntp', require: false
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false
end

# The test group will be
# installed on Travis CI
#
group :test do
  gem 'rspec', '~> 3.1', require: false
  gem 'fakefs', require: false
  gem 'coveralls', require: false
end

gem 'therubyrhino', platforms: :jruby
gem 'therubyracer', platforms: :ruby
