class CreateAuthProfiles < ActiveRecord::Migration
  def change
    create_table :auth_profiles do |t|
      t.integer :user_id
      t.integer :company_id
      t.string :openid, null: false
      t.string :provider
      t.string :nickname
      t.string :sex
      t.string :headimgurl
      t.string :city
      t.string :language
      t.string :province
      t.string :country
      t.string :unionid
      t.string :access_token
      t.string :refresh_token

      t.timestamps null: false
    end
    add_index :auth_profiles, :user_id
    add_index :auth_profiles, :company_id
    add_index :auth_profiles, :openid
  end
end
