require 'spec_helper'

describe "Checkout", type: :feature, inaccessible: true do
  include_context 'checkout setup'

  context "user has payment sources", js: true do
    let(:bogus) { create(:credit_card_payment_method) }
    let(:user) { create(:user) }

    let!(:credit_card) do
      create(:credit_card, user_id: user.id, payment_method: bogus, gateway_customer_profile_id: "BGS-WEFWF")
    end

    before do
      login_as(user)
      user.wallet.add(credit_card)
      order = OrderWalkthrough.up_to(:delivery)
      allow(order).to receive_messages(available_payment_methods: [bogus])

      allow_any_instance_of(Spree::CheckoutController).to receive_messages(
        current_order: order,
        try_spree_current_user: user,
        check_authorization: true
      )
      allow_any_instance_of(Spree::OrdersController).to receive_messages(try_spree_current_user: user)

      visit spree.checkout_state_path(:payment)
    end

    it "selects first source available and customer moves on" do
      expect(find("#use_existing_card_yes")).to be_checked

      expect {
        click_on "Save and Continue"
      }.not_to change { Spree::CreditCard.count }

      sleep 50

      click_on "Place Order"
      expect(page).to have_current_path(spree.order_path(Spree::Order.last))
    end

    it "allows user to enter a new source" do
      choose "use_existing_card_no"

      fill_in "Name on card", with: 'Spree Commerce'
      fill_in "Card Number", with: '4111111111111111'
      fill_in "card_expiry", with: '04 / 20'
      fill_in "Card Code", with: '123'

      expect {
        click_on "Save and Continue"
      }.to change { Spree::CreditCard.count }.by 1

      expect(Spree::CreditCard.last.address).to be_present

      click_on "Place Order"
      expect(page).to have_current_path(spree.order_path(Spree::Order.last))
    end
  end
end
