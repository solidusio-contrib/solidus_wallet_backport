module SolidusWalletBackport
  module AppConfigurationDecorator
    # Allows providing your own class for adding default payments to a user's
    # order from their "wallet".
    #
    # @!attribute [rw] default_payment_builder_class
    # @return [Class] a class with the same public interfaces as
    #   Spree::Wallet::DefaultPaymentBuilder.
    attr_writer :default_payment_builder_class
    def default_payment_builder_class
      @default_payment_builder_class ||= Spree::Wallet::DefaultPaymentBuilder
    end

    # Allows providing your own class for adding payment sources to a user's
    # "wallet" after an order moves to the complete state.
    #
    # @!attribute [rw] add_payment_sources_to_wallet_class
    # @return [Class] a class with the same public interfaces
    #   as Spree::Wallet::AddPaymentSourcesToWallet.
    attr_writer :add_payment_sources_to_wallet_class
    def add_payment_sources_to_wallet_class
      @add_payment_sources_to_wallet_class ||= Spree::Wallet::AddPaymentSourcesToWallet
    end
  end
end

Spree::AppConfiguration.prepend SolidusWalletBackport::AppConfigurationDecorator
