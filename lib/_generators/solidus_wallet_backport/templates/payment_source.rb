module Spree
  class RomanWallet < Spree::PaymentSource
    def reusable?
      true
    end
  end
end
