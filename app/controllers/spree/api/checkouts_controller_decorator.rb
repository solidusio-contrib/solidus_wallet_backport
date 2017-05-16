module SolidusWalletBackport
  module Api
    module CheckoutsControllerDecorator
      def update
        authorize! :update, @order, order_token

        if Spree::OrderUpdateAttributes.new(@order, update_params, request_env: request.headers.env).apply
          if can?(:admin, @order) && user_id.present?
            @order.associate_user!(Spree.user_class.find(user_id))
          end

          return if after_update_attributes

          if @order.completed? || @order.next
            state_callback(:after)
            respond_with(@order, default_template: 'spree/api/orders/show')
          else
            logger.error("failed_to_transition_errors=#{@order.errors.full_messages}")
            respond_with(@order, default_template: 'spree/api/orders/could_not_transition', status: 422)
          end
        else
          invalid_resource!(@order)
        end
      end

      private

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
        set_payment_parameters_amount(massaged_params, @order)
        massaged_params
      end

      def set_payment_parameters_amount(params, order)
        return params if params[:order].blank?
        return params if params[:order][:payments_attributes].blank?

        params[:order][:payments_attributes].first[:amount] = order.total

        params
      end
    end
  end
end

Spree::Api::CheckoutsController.prepend SolidusWalletBackport::Api::CheckoutsControllerDecorator
