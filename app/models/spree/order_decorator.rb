module SolidusWalletBackport
  module OrderDecorator
    attr_accessor :temporary_payment_source

    alias_method :temporary_credit_card, :temporary_payment_source
    alias_method :temporary_credit_card=, :temporary_payment_source=

    def add_payment_sources_to_wallet
      Spree::Config.
        add_payment_sources_to_wallet_class.new(self).
        add_to_wallet
    end
    alias_method :persist_user_credit_card, :add_payment_sources_to_wallet

    def add_default_payment_from_wallet
      builder = Spree::Config.default_payment_builder_class.new(self)

      if payment = builder.build
        payments << payment

        if bill_address.nil?
          # this is one of 2 places still using User#bill_address
          self.bill_address = payment.source.try(:address) ||
                              user.bill_address
        end
      end
    end
    alias_method :assign_default_credit_card, :add_default_payment_from_wallet
  end
end

Spree::Order.prepend SolidusWalletBackport::OrderDecorator
