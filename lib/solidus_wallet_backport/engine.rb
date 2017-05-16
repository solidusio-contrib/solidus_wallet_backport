module SolidusWalletBackport
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'solidus_wallet_backport'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "solidus_wallet_backport.permitted_attributes", before: :load_config_initializers do
      Spree::PermittedAttributes.source_attributes << :wallet_payment_source_id
      Spree::PermittedAttributes.source_attributes << :existing_card_id
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
