class CreateMerchAccounts < ActiveRecord::Migration
  def change
    create_table :merch_accounts do |t|
      t.integer :company_id
      t.integer :merchant_id
      t.string :name, null: false
      t.string :avatar
      t.string :mobile
      t.string :password_digest
      t.string :private_token
      t.boolean :is_admin, default: false
      t.integer :role
      t.boolean :opened, default: true
      t.datetime :deleted_at
      t.datetime :last_login_at
      t.string :last_login_ip
      t.string :memo

      t.timestamps null: false
    end
    add_index :merch_accounts, :company_id
    add_index :merch_accounts, :merchant_id
    add_index :merch_accounts, :private_token, unique: true
  end
end
