# encoding: utf-8

source 'https://rubygems.org'

gemspec

if Gem.ruby_version < Gem::Version.new('2.0')
  # gems that no longer support ruby 1.9.3
  gem 'json', '~> 1.8.3'
  gem 'tins', '~> 1.6.0'
  gem 'term-ansicolor', '~> 1.3.2'
end
if Gem.ruby_version >= Gem::Version.new('2.1')
  gem 'devtools', '~> 0.1.4'
end
gem 'fuubar', '~> 2.0.0'
gem 'awesome_print'

gem 'rake'
gem 'rspec', '~> 3.5'
gem 'rspec-its'
gem 'coveralls', '~> 0.8.9'

platform :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end
