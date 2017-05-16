# encoding: UTF-8
$:.push File.expand_path('../lib', __FILE__)
require 'solidus_wallet_backport/version'

Gem::Specification.new do |s|
  s.name        = 'solidus_wallet_backport'
  s.version     = SolidusWalletBackport::VERSION
  s.summary     = 'Backport of the Spree::Wallet and "Non credit card payment
                   sources" features from Solidus 2.2'
  s.description = s.summary
  s.license     = 'BSD-3-Clause'

  s.author    = 'Alessandro Lepore'
  s.email     = 'alessandro@stembolt.com'
  s.homepage  = 'https://github.com/alepore'

  s.files = Dir["{app,config,db,lib}/**/*", 'LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'solidus_core', ['>= 1.0', '< 2.2']
  s.add_dependency 'solidus_support'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'rspec-rails', '~> 3.5.0'
  s.add_development_dependency 'rubocop', '0.43.0'
  s.add_development_dependency 'rubocop-rspec', '1.4.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'with_model'
  s.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0.2'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'launchy'
end
