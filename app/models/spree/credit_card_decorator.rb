module SolidusWalletBackport
  module CreditCardDecorator
    attr_accessor :verification_value

    def self.prepended(base)
      base.belongs_to :payment_method
      base.has_many :wallet_payment_sources, class_name: 'Spree::WalletPaymentSource', as: :payment_source, inverse_of: :payment_source
      base.scope :default, -> {
        joins(:wallet_payment_sources).where(spree_wallet_payment_sources: { default: true })
      }
    end

    def default
      return false if user.nil?
      user.wallet.default_wallet_payment_source.try!(:payment_source) == self
    end

    def default=(set_as_default)
      if user.nil?
        raise "Cannot set 'default' on a credit card without a user"
      elsif set_as_default # setting this card as default
        wallet_payment_source = user.wallet.add(self)
        user.wallet.default_wallet_payment_source = wallet_payment_source
        true
      else # removing this card as default
        if user.wallet.default_wallet_payment_source.try!(:payment_source) == self
          user.wallet.default_wallet_payment_source = nil
        end
        false
      end
    end

    def reusable?
      has_payment_profile?
    end

    private

    def ensure_one_default
      true
    end
  end
end

Spree::CreditCard.prepend SolidusWalletBackport::CreditCardDecorator
