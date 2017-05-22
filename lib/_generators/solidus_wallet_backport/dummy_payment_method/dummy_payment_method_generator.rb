module SolidusWalletBackport
  module Generators
    class DummyPaymentMethodGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../../templates', __FILE__)

      ENV["RAILS_ENV"] = 'test'

      def self.next_migration_number(*)
        if @prev_migration_nr
          @prev_migration_nr = @prev_migration_nr += 1
        else
          @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i + 1000
        end
      end

      def add_classes
        template 'payment_method.rb', 'app/models/spree/payment_method/roman.rb'
        template 'payment_source.rb', 'app/models/spree/roman_wallet.rb'
      end

      def add_partials
        template 'payment_partial.html.erb', 'app/views/spree/checkout/payment/_roman.html.erb'
        template 'existing_payment_partial.html.erb', 'app/views/spree/checkout/existing_payment/_roman.html.erb'
      end

      def add_config
        append_file 'config/initializers/spree.rb', 'Rails.application.config.spree.payment_methods << Spree::PaymentMethod::Roman'
      end

      def add_migrations
        migration_template 'payment_source_migration.rb', "db/migrate/create_spree_roman_wallets.rb"
      end

      def run_migrations
        run 'bundle exec rake db:migrate'
      end
    end
  end
end
