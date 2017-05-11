require 'spec_helper'

describe Spree::Gateway, type: :model do
  context "fetching payment sources" do
    let(:store) { create :store }
    let(:user) { create :user }
    let(:order) { Spree::Order.create(user: user, completed_at: completed_at, store: store) }

    let(:payment_method) { create(:credit_card_payment_method) }

    let(:cc) do
      create(:credit_card,
             payment_method: payment_method,
             gateway_customer_profile_id: "EFWE",
             user: cc_user)
    end

    let(:payment) do
      create(:payment, order: order, source: cc, payment_method: payment_method)
    end

    context 'order is not complete but credit card has user' do
      let(:cc_user) { user }
      let(:completed_at) { nil }
      before do
        cc_user.wallet.add(cc)
      end
      it "finds credit cards associated to the user" do
        expect(payment_method.reusable_sources(payment.order)).to eq [cc]
      end
    end
  end
end
