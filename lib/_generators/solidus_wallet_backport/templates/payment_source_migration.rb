class CreateSpreeRomanWallets < SolidusSupport::Migration[4.2]
  def change
    create_table :spree_roman_wallets do |t|
      t.string :name
      t.integer :payment_method_id
    end
  end
end
