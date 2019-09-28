class CreateMerchants < ActiveRecord::Migration
  def change
    create_table :merchants do |t|
      t.integer :company_id
      t.integer :from_account_id # 业务推广员
      t.string :name, null: false
      t.string :brand
      t.string :logo
      t.string :mobile
      t.string :license_no
      t.string :license_image
      t.string :address
      t.boolean :opened, default: true
      t.datetime :deleted_at
      t.string :memo

      t.timestamps null: false
    end
    add_index :merchants, :company_id
  end
end
