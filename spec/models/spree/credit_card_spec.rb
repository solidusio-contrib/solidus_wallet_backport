require 'spec_helper'

describe Spree::CreditCard, type: :model do
  let(:valid_credit_card_attributes) do
    {
      number: '4111111111111111',
      verification_value: '123',
      expiry: "12 / #{(Time.current.year + 1).to_s.last(2)}",
      name: 'Spree Commerce'
    }
  end

  def self.payment_states
    Spree::Payment.state_machine.states.keys
  end

  let(:credit_card) { Spree::CreditCard.new }

  it_behaves_like 'a payment source'

  before(:each) do
    @order = create(:order)
    @payment = Spree::Payment.create(amount: 100, order: @order)

    @success_response = double('gateway_response', success?: true, authorization: '123', avs_result: { 'code' => 'avs-code' })
    @fail_response = double('gateway_response', success?: false)

    @payment_gateway = mock_model(Spree::PaymentMethod,
      payment_profiles_supported?: true,
      authorize: @success_response,
      purchase: @success_response,
      capture: @success_response,
      void: @success_response,
      credit: @success_response)

    allow(@payment).to receive_messages payment_method: @payment_gateway
  end

  # TODO: Remove these specs once default is removed
  describe 'default' do
    def default_with_silence(card)
      Spree::Deprecation.silence { card.default }
    end

    context 'with a user' do
      let(:user) { create(:user) }
      let(:credit_card) { create(:credit_card, user: user) }

      it 'uses the wallet information' do
        wallet_payment_source = user.wallet.add(credit_card)
        user.wallet.default_wallet_payment_source = wallet_payment_source

        expect(default_with_silence(credit_card)).to be_truthy
      end
    end

    context 'without a user' do
      let(:credit_card) { create(:credit_card) }

      it 'returns false' do
        expect(default_with_silence(credit_card)).to eq(false)
      end
    end
  end

  # TODO: Remove these specs once default= is removed
  describe 'default=' do
    def default_with_silence(card)
      Spree::Deprecation.silence { card.default }
    end

    context 'with a user' do
      let(:user) { create(:user) }
      let(:credit_card) { create(:credit_card, user: user) }

      it 'updates the wallet information' do
        Spree::Deprecation.silence do
          credit_card.default = true
        end
        expect(user.wallet.default_wallet_payment_source.payment_source).to eq(credit_card)
      end
    end

    context 'with multiple cards for one user' do
      let(:user) { create(:user) }
      let(:first_card) { create(:credit_card, user: user) }
      let(:second_card) { create(:credit_card, user: user) }

      it 'ensures only one default' do
        Spree::Deprecation.silence do
          first_card.default = true
          second_card.default = true
        end

        expect(default_with_silence(first_card)).to be_falsey
        expect(default_with_silence(second_card)).to be_truthy

        Spree::Deprecation.silence do
          first_card.default = true
        end

        expect(default_with_silence(first_card)).to be_truthy
        expect(default_with_silence(second_card)).to be_falsey
      end
    end

    context 'with multiple cards for different users' do
      let(:first_card) { create(:credit_card, user: create(:user)) }
      let(:second_card) { create(:credit_card, user: create(:user)) }

      it 'allows multiple defaults' do
        Spree::Deprecation.silence do
          first_card.default = true
          second_card.default = true
        end

        expect(default_with_silence(first_card)).to be_truthy
        expect(default_with_silence(second_card)).to be_truthy
      end
    end

    context 'without a user' do
      let(:credit_card) { create(:credit_card) }

      it 'raises' do
        expect {
          Spree::Deprecation.silence do
            credit_card.default = true
          end
        }.to raise_error("Cannot set 'default' on a credit card without a user")
      end
    end
  end
end
