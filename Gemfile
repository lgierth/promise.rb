# encoding: utf-8

source 'https://rubygems.org'

gemspec

gem 'devtools', git: 'https://github.com/rom-rb/devtools.git'
gem 'fuubar',   git: 'https://github.com/lgierth/fuubar.git',
                ref: 'static-percentage'
gem 'awesome_print'

platform :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubysl-json', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end

# Added by devtools
eval_gemfile 'Gemfile.devtools'
