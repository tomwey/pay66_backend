class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.integer :company_id
      t.integer :user_id
      t.integer :merchant_id
      t.boolean :opened, default: true
      t.datetime :deleted_at
      t.string :memo

      t.timestamps null: false
    end
    add_index :memberships, :company_id
    add_index :memberships, :user_id
    add_index :memberships, :merchant_id
  end
end
