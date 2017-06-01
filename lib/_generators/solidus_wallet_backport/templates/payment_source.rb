module Spree
  class RomanWallet < Spree::Base
    include SolidusWalletBackport::PaymentSource

    def reusable?
      true
    end
  end
end
