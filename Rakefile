require 'bundler'

Bundler::GemHelper.install_tasks

begin
  require 'spree/testing_support/extension_rake'
  require 'rubocop/rake_task'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  RuboCop::RakeTask.new

  task default: %i(first_run rubocop spec)
rescue LoadError
  # no rspec available
end

task :first_run do
  if Dir['spec/dummy'].empty?
    Rake::Task[:test_app].invoke
    Dir.chdir('../../')
  end
end

desc 'Generates a dummy app for testing'
task :test_app do
  ENV['LIB_NAME'] = 'solidus_wallet_backport'
  Rake::Task['extension:test_app'].invoke
  Rake::Task[:dummy_payment_method].invoke
end

desc 'Adds a custom payment method to the test app'
task :dummy_payment_method do
  require_relative 'lib/generators/solidus_wallet_backport/dummy_payment_method/dummy_payment_method_generator'
  SolidusWalletBackport::Generators::DummyPaymentMethodGenerator.start
end
