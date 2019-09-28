class CreateShops < ActiveRecord::Migration
  def change
    create_table :shops do |t|
      t.integer :company_id
      t.integer :merchant_id
      t.string :name, null: false
      t.integer :_type
      t.string :outer_images
      t.string :inner_images
      t.string :phone
      t.string :scope
      t.string :address
      t.datetime :deleted_at
      t.string :memo

      t.timestamps null: false
    end
    add_index :shops, :company_id
    add_index :shops, :merchant_id
    add_index :shops, :_type
  end
end
