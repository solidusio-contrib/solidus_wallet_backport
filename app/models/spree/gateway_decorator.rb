module SolidusWalletBackport
  module GatewayDecorator
    def reusable_sources_by_order(order)
      source_ids = order.payments.where(payment_method_id: id).pluck(:source_id).uniq
      payment_source_class.where(id: source_ids).select(&:reusable?)
    end
    alias_method :sources_by_order, :reusable_sources_by_order
  end
end

Spree::Gateway.prepend SolidusWalletBackport::GatewayDecorator
