class CreateMerchAuths < ActiveRecord::Migration
  def change
    create_table :merch_auths do |t|
      t.integer :company_id
      t.integer :merchant_id
      t.string :provider
      t.string :app_auth_token, null: false
      t.string :app_refresh_token
      t.string :auth_app_id
      t.string :expires_in
      t.string :re_expires_in
      t.string :userid
      t.datetime :deleted_at

      t.timestamps null: false
    end
    add_index :merch_auths, :company_id
    add_index :merch_auths, :merchant_id
  end
end
