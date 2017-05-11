module SolidusWalletBackport
  module UserDecorator
    def self.prepended(base)
      base.has_many :credit_cards, class_name: "Spree::CreditCard", foreign_key: :user_id
      base.has_many :wallet_payment_sources, foreign_key: 'user_id', class_name: 'Spree::WalletPaymentSource', inverse_of: :user
    end

    def wallet
     Spree::Wallet.new(self)
    end

    def default_credit_card
      default = wallet.default_wallet_payment_source
      if default && default.payment_source.is_a?(Spree::CreditCard)
        default.payment_source
      end
    end
  end
end

Spree::User.prepend SolidusWalletBackport::UserDecorator
