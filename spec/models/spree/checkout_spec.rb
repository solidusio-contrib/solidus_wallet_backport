require 'spec_helper'
require 'spree/testing_support/order_walkthrough'

describe Spree::Order, type: :model do
  let!(:store) { create(:store) }
  let(:order) { Spree::Order.new(store: store) }

  def assert_state_changed(order, from, to)
    state_change_exists = order.state_changes.where(previous_state: from, next_state: to).exists?
    assert state_change_exists, "Expected order to transition from #{from} to #{to}, but didn't."
  end

  context "with default state machine" do
    transitions = [
      { address: :delivery },
      { delivery: :payment },
      { payment: :confirm },
      { delivery: :confirm }
    ]

    transitions.each do |transition|
      it "transitions from #{transition.keys.first} to #{transition.values.first}" do
        transition = Spree::Order.find_transition(from: transition.keys.first, to: transition.values.first)
        expect(transition).not_to be_nil
      end
    end

    context "to payment" do
      let(:user_bill_address)   { nil }
      let(:order_bill_address)  { nil }
      let(:default_credit_card) { create(:credit_card) }

      before do
        user = create(:user, email: 'spree@example.org', bill_address: user_bill_address)
        wallet_payment_source = user.wallet.add(default_credit_card)
        user.wallet.default_wallet_payment_source = wallet_payment_source
        order.user = user

        allow(order).to receive_messages(payment_required?: true)
        order.state = 'delivery'
        order.bill_address = order_bill_address
        order.save!
        order.next!
        order.reload
      end

      it "assigns the user's default credit card" do
        expect(order.state).to eq 'payment'
        expect(order.payments.count).to eq 1
        expect(order.payments.first.source).to eq default_credit_card
      end

      context "order already has a billing address" do
        let(:order_bill_address) { create(:address) }

        it "keeps the order's billing address" do
          expect(order.bill_address).to eq order_bill_address
        end
      end

      context "order doesn't have a billing address" do
        it "assigns the user's default_credit_card's address to the order" do
          expect(order.bill_address).to eq default_credit_card.address
        end
      end
    end
  end

  context "to complete" do
    before do
      order.state = 'confirm'
      order.save!
    end

    context "default credit card" do
      before do
        order.user = FactoryGirl.create(:user)
        order.store = FactoryGirl.create(:store)
        order.email = 'spree@example.org'
        order.payments << FactoryGirl.create(:payment)

        # make sure we will actually capture a payment
        allow(order).to receive_messages(payment_required?: true)
        allow(order).to receive_messages(ensure_available_shipping_rates: true)
        allow(order).to receive_messages(validate_line_item_availability: true)
        order.line_items << FactoryGirl.create(:line_item)
        order.create_proposed_shipments
        Spree::OrderUpdater.new(order).update

        order.save!
      end

      it "makes the current credit card a user's default credit card" do
        order.complete!
        expect(order.state).to eq 'complete'
        expect(order.user.reload.wallet.default_wallet_payment_source.payment_source).to eq(order.credit_cards.first)
      end

      it "does not assign a default credit card if temporary_payment_source is set" do
        order.temporary_payment_source = true
        order.complete!
        expect(order.user.reload.wallet.default_wallet_payment_source).to be_nil
      end
    end
  end
end
