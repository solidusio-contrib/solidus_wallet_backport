require 'spec_helper'

module Spree
  describe Api::CheckoutsController, type: :controller do
    render_views

    before(:each) do
      stub_authentication!
      Spree::Config[:track_inventory_levels] = false
      country_zone = create(:zone, name: 'CountryZone')
      @state = create(:state)
      @country = @state.country
      country_zone.members.create(zoneable: @country)
      create(:stock_location)

      @shipping_method = create(:shipping_method, zones: [country_zone])
      @payment_method = create(:credit_card_payment_method)

      allow(@controller).to receive(:requested_version).and_return(1)
    end

    after do
      Spree::Config[:track_inventory_levels] = true
    end

    context "PUT 'update'" do
      let(:order) do
        order = create(:order_with_line_items)
        # Order should be in a pristine state
        # Without doing this, the order may transition from 'cart' straight to 'delivery'
        order.shipments.delete_all
        order
      end

      before(:each) do
        allow_any_instance_of(Order).to receive_messages(payment_required?: true)
      end

      context 'reusing a credit card' do
        before do
          order.update_column(:state, "payment")
        end

        let(:params) do
          {
            id: order.to_param,
            order_token: order.guest_token,
            order: {
              payments_attributes: [
                {
                  source_attributes: {
                    wallet_payment_source_id: wallet_payment_source.id.to_param,
                    verification_value: '456'
                  }
                }
              ]
            }
          }
        end

        let!(:wallet_payment_source) do
          order.user.wallet.add(credit_card)
        end

        let(:credit_card) do
          create(:credit_card, user_id: order.user_id, payment_method_id: @payment_method.id)
        end

        it 'succeeds' do
          # unfortunately the credit card gets reloaded by `@order.next` before
          # the controller action finishes so this is the best way I could think
          # of to test that the verification_value gets set.
          expect_any_instance_of(Spree::CreditCard).to(
            receive(:verification_value=).with('456').and_call_original
          )

          api_put(:update, params)

          expect(response.status).to eq 200
          expect(order.credit_cards).to match_array [credit_card]
        end

        context 'with deprecated existing_card_id param' do
          let(:params) do
            {
              id: order.to_param,
              order_token: order.guest_token,
              order: {
                payments_attributes: [
                  {
                    source_attributes: {
                      existing_card_id: credit_card.id.to_param,
                      verification_value: '456'
                    }
                  }
                ]
              }
            }
          end

          it 'succeeds' do
            api_put(:update, params)

            expect(response.status).to eq 200
            expect(order.credit_cards).to match_array [credit_card]
          end
        end
      end
    end
  end
end
