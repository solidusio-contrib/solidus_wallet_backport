module SolidusWalletBackport
  module StoreCreditDecorator
    attr_accessor :imported

    def self.prepended(base)
      base.belongs_to :payment_method
      base.has_many :payments, as: :source
      base.has_many :wallet_payment_sources, class_name: 'Spree::WalletPaymentSource', as: :payment_source, inverse_of: :payment_source
    end

    def reusable?
      false
    end
  end
end

Spree::StoreCredit.prepend SolidusWalletBackport::StoreCreditDecorator
