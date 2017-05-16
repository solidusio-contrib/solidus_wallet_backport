module SolidusWalletBackport
  module CheckoutControllerDecorator
    # Updates the order and advances to the next state (when possible.)
    def update
      if update_order
        assign_temp_address

        unless transition_forward
          redirect_on_failure
          return
        end

        if @order.completed?
          finalize_order
        else
          send_to_next_state
        end
      else
        render :edit
      end
    end

    private

    def update_order
      Spree::OrderUpdateAttributes.new(@order, update_params, request_env: request.headers.env).apply
    end

    def assign_temp_address
      @order.temporary_address = !params[:save_user_address]
    end

    def redirect_on_failure
      flash[:error] = @order.errors.full_messages.join("\n")
      redirect_to(checkout_state_path(@order.state))
    end

    def transition_forward
      if @order.state == 'confirm'
        @order.complete
      else
        @order.next
      end
    end

    def finalize_order
      @current_order = nil
      set_successful_flash_notice
      redirect_to completion_route
    end

    def set_successful_flash_notice
      flash.notice = Spree.t(:order_processed_successfully)
      flash['order_completed'] = true
    end

    def send_to_next_state
      redirect_to checkout_state_path(@order.state)
    end

    def update_params
      if update_params = massaged_params[:order]
        update_params.permit(permitted_checkout_attributes)
      else
        # We current allow update requests without any parameters in them.
        {}
      end
    end

    def massaged_params
      massaged_params = params.deep_dup

      move_payment_source_into_payments_attributes(massaged_params)
      if massaged_params[:order] && massaged_params[:order][:existing_card].present?
        move_existing_card_into_payments_attributes(massaged_params) # deprecated
      end
      move_wallet_payment_source_id_into_payments_attributes(massaged_params)
      set_payment_parameters_amount(massaged_params, @order)

      massaged_params
    end

    def before_payment
      if @order.checkout_steps.include? "delivery"
        packages = @order.shipments.map(&:to_package)
        @differentiator = Spree::Stock::Differentiator.new(@order, packages)
        @differentiator.missing.each do |variant, quantity|
          @order.contents.remove(variant, quantity)
        end
      end

      if try_spree_current_user && try_spree_current_user.respond_to?(:wallet)
        @wallet_payment_sources = try_spree_current_user.wallet.wallet_payment_sources
        @default_wallet_payment_source = @wallet_payment_sources.detect(&:default) ||
                                         @wallet_payment_sources.first
        @payment_sources = try_spree_current_user.wallet.wallet_payment_sources.map(&:payment_source).select { |ps| ps.is_a?(Spree::CreditCard) }
      end
    end

    # This method handles the awkwardness of how the html forms are currently
    # set up for frontend.
    #
    # This method expects a params hash in the format of:
    #
    #  {
    #    payment_source: {
    #      # The keys here are spree_payment_method.id's
    #      '1' => {...source attributes for payment method 1...},
    #      '2' => {...source attributes for payment method 2...},
    #    },
    #    order: {
    #      # Note that only a single entry is expected/handled in this array
    #      payments_attributes: [
    #        {
    #          payment_method_id: '1',
    #        },
    #      ],
    #      ...other params...
    #    },
    #    ...other params...
    #  }
    #
    # And this method modifies the params into the format of:
    #
    #  {
    #    order: {
    #      payments_attributes: [
    #        {
    #          payment_method_id: '1',
    #          source_attributes: {...source attributes for payment method 1...}
    #        },
    #      ],
    #      ...other params...
    #    },
    #    ...other params...
    #  }
    #
    def move_payment_source_into_payments_attributes(params)
      # Step 1: Gather all the information and ensure all the pieces are there.

      return params if params[:payment_source].blank?

      payment_params = params[:order] &&
                       params[:order][:payments_attributes] &&
                       params[:order][:payments_attributes].first
      return params if payment_params.blank?

      payment_method_id = payment_params[:payment_method_id]
      return params if payment_method_id.blank?

      source_params = params[:payment_source][payment_method_id]
      return params if source_params.blank?

      # Step 2: Perform the modifications.

      payment_params[:source_attributes] = source_params
      params.delete(:payment_source)

      params
    end

    # This method handles the awkwardness of how the html forms are currently
    # set up for frontend.
    #
    # This method expects a params hash in the format of:
    #
    #  {
    #    order: {
    #      existing_card: '123',
    #      ...other params...
    #    },
    #    cvc_confirm: '456', # optional
    #    ...other params...
    #  }
    #
    # And this method modifies the params into the format of:
    #
    #  {
    #    order: {
    #      payments_attributes: [
    #        {
    #          source_attributes: {
    #            existing_card_id: '123',
    #            verification_value: '456',
    #          },
    #        },
    #      ]
    #      ...other params...
    #    },
    #    ...other params...
    #  }
    #
    def move_existing_card_into_payments_attributes(params)
      return params if params[:order].blank?

      card_id = params[:order][:existing_card].presence
      cvc_confirm = params[:cvc_confirm].presence

      return params if card_id.nil?

      params[:order][:payments_attributes] = [
        {
          source_attributes: {
            existing_card_id: card_id,
            verification_value: cvc_confirm
          }
        }
      ]

      params[:order].delete(:existing_card)
      params.delete(:cvc_confirm)

      params
    end

    # This method handles the awkwardness of how the html forms are currently
    # set up for frontend.
    #
    # This method expects a params hash in the format of:
    #
    #  {
    #    order: {
    #      wallet_payment_source_id: '123',
    #      ...other params...
    #    },
    #    cvc_confirm: '456', # optional
    #    ...other params...
    #  }
    #
    # And this method modifies the params into the format of:
    #
    #  {
    #    order: {
    #      payments_attributes: [
    #        {
    #          source_attributes: {
    #            wallet_payment_source_id: '123',
    #            verification_value: '456',
    #          },
    #        },
    #      ]
    #      ...other params...
    #    },
    #    ...other params...
    #  }
    #
    def move_wallet_payment_source_id_into_payments_attributes(params)
      return params if params[:order].blank?

      wallet_payment_source_id = params[:order][:wallet_payment_source_id].presence
      cvc_confirm = params[:cvc_confirm].presence

      return params if wallet_payment_source_id.nil?

      params[:order][:payments_attributes] = [
        {
          source_attributes: {
            wallet_payment_source_id: wallet_payment_source_id,
            verification_value: cvc_confirm
          }
        }
      ]

      params[:order].delete(:wallet_payment_source_id)
      params.delete(:cvc_confirm)

      params
    end

    # This is a strange thing to do since an order can have multiple payments
    # but we always assume that it only has a single payment and that its
    # amount should be the current order total.  Also, this is pretty much
    # overridden when the order transitions to confirm by the logic inside of
    # Order#add_store_credit_payments.
    # We should reconsider this method and its usage at some point.
    #
    # This method expects a params hash in the format of:
    #
    #  {
    #    order: {
    #      # Note that only a single entry is expected/handled in this array
    #      payments_attributes: [
    #        {
    #          ...params...
    #        },
    #      ],
    #      ...other params...
    #    },
    #    ...other params...
    #  }
    #
    # And this method modifies the params into the format of:
    #
    #  {
    #    order: {
    #      payments_attributes: [
    #        {
    #          ...params...
    #          amount: <the order total>,
    #        },
    #      ],
    #      ...other params...
    #    },
    #    ...other params...
    #  }
    #
    def set_payment_parameters_amount(params, order)
      return params if params[:order].blank?
      return params if params[:order][:payments_attributes].blank?

      params[:order][:payments_attributes].first[:amount] = order.total

      params
    end
  end
end

Spree::CheckoutController.prepend SolidusWalletBackport::CheckoutControllerDecorator
