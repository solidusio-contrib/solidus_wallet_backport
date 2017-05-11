require 'spec_helper'

describe Spree::Payment, type: :model do
  let(:store) { create :store }
  let(:order) { Spree::Order.create(store: store) }
  let(:refund_reason) { create(:refund_reason) }

  let(:gateway) do
    gateway = Spree::Gateway::Bogus.new(active: true, name: 'Bogus gateway')
    allow(gateway).to receive_messages source_required: true
    gateway
  end

  let(:avs_code) { 'D' }
  let(:cvv_code) { 'M' }

  let(:card) { create :credit_card }

  let(:payment) do
    Spree::Payment.create! do |payment|
      payment.source = card
      payment.order = order
      payment.payment_method = gateway
      payment.amount = 5
    end
  end

  let(:amount_in_cents) { (payment.amount * 100).round }

  let!(:success_response) do
    ActiveMerchant::Billing::Response.new(true, '', {}, {
      authorization: '123',
      cvv_result: cvv_code,
      avs_result: { code: avs_code }
    })
  end

  let(:failed_response) do
    ActiveMerchant::Billing::Response.new(false, '', {}, {})
  end

  # This used to describe #apply_source_attributes, whose behaviour is now part of PaymentCreate
  describe "#apply_source_attributes" do
    context 'with an existing credit card' do
      let(:order) { create(:order, user: user) }
      let(:user) { create(:user) }
      let!(:credit_card) { create(:credit_card, user_id: order.user_id) }
      let!(:wallet_payment_source) { user.wallet.add(credit_card) }

      let(:params) do
        {
          source_attributes: {
            wallet_payment_source_id: wallet_payment_source.id,
            verification_value: '321'
          }
        }
      end

      describe "building a payment" do
        subject do
          Spree::PaymentCreate.new(order, params).build.save!
        end

        it 'sets the existing card as the source for the new payment' do
          expect {
            subject
          }.to change { Spree::Payment.count }.by(1)

          expect(order.payments.last.source).to eq(credit_card)
        end

        it 'sets the payment payment_method to that of the credit card' do
          subject
          expect(order.payments.last.payment_method_id).to eq(credit_card.payment_method_id)
        end

        it 'sets the verification_value on the credit card' do
          subject
          expect(order.payments.last.source.verification_value).to eq('321')
        end

        it 'sets the request_env on the payment' do
          payment = Spree::PaymentCreate.new(order, params.merge(request_env: { 'USER_AGENT' => 'Firefox' })).build
          payment.save!
          expect(payment.request_env).to eq({ 'USER_AGENT' => 'Firefox' })
        end

        context 'the credit card belongs to a different user' do
          let(:other_user) { create(:user) }
          before do
            credit_card.update!(user_id: other_user.id)
            user.wallet.remove(credit_card)
            other_user.wallet.add(credit_card)
          end
          it 'errors' do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'the credit card has no user' do
          before do
            credit_card.update!(user_id: nil)
            user.wallet.remove(credit_card)
          end
          it 'errors' do
            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end
end
