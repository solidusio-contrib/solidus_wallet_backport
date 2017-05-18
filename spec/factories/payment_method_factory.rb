FactoryGirl.define do
  factory :roman_payment_method, class: Spree::PaymentMethod::Roman do
    name "Roman payment method"
    active true
  end
end
