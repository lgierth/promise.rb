# encoding: utf-8

source 'https://rubygems.org'

gemspec

if Gem.ruby_version < Gem::Version.new('2.0')
  # gems that no longer support ruby 1.9.3
  gem 'json', '~> 1.8.3'
  gem 'term-ansicolor', '~> 1.3.2'
  gem 'tins', '~> 1.6.0'
end
if Gem.ruby_version >= Gem::Version.new('2.1')
  gem 'devtools', '~> 0.1.16'
end

gem 'awesome_print'
gem 'coveralls', '~> 0.8.9'
gem 'fuubar', '~> 2.0.0'
gem 'rake'
gem 'rspec', '~> 3.5'
gem 'rspec-its'

platform :rbx do
  gem 'rubinius', '~> 2.0'
  gem 'rubysl', '~> 2.0'
end
