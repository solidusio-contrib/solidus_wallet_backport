module SolidusWalletBackport
  module PaymentCreateDecorator
    # Build the new Payment
    # @return [Payment] a new (unpersisted) Payment
    def build
      @payment ||= order.payments.new
      @payment.request_env = @request_env if @request_env
      @payment.attributes = @attributes

      if source_attributes[:existing_card_id].present?
        build_existing_card
      elsif source_attributes[:wallet_payment_source_id].present?
        build_from_wallet_payment_source
      else
        build_source
      end

      @payment
    end

    private

    def build_source
      payment_method = payment.payment_method
      if source_attributes.present? && payment_method.try(:payment_source_class)
        payment.source = payment_method.payment_source_class.new(source_attributes)
        payment.source.payment_method_id = payment_method.id
        if order && payment.source.respond_to?(:user=)
          payment.source.user = order.user
        end
      end
    end

    def build_from_wallet_payment_source
      wallet_payment_source_id = source_attributes.fetch(:wallet_payment_source_id)
      raise(ActiveRecord::RecordNotFound) if order.user.nil?
      wallet_payment_source = order.user.wallet.find(wallet_payment_source_id)
      raise(ActiveRecord::RecordNotFound) if wallet_payment_source.nil?
      build_from_payment_source(wallet_payment_source.payment_source)
    end

    def build_existing_card
      credit_card = available_cards.find(source_attributes[:existing_card_id])
      build_from_payment_source(credit_card)
    end

    def build_from_payment_source(payment_source)
      # FIXME: does this work?
      if source_attributes[:verification_value]
        payment_source.verification_value = source_attributes[:verification_value]
      end

      payment.source = payment_source
      payment.payment_method_id = payment_source.payment_method_id
    end
  end
end

Spree::PaymentCreate.prepend SolidusWalletBackport::PaymentCreateDecorator
