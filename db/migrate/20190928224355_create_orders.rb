class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :order_no
      t.string :title, null: false # 订单描述
      t.integer :company_id
      t.integer :merchant_id
      t.integer :shop_id
      t.integer :device_id
      t.integer :money
      t.integer :fee_rate
      t.integer :l1_earn
      t.integer :l2_earn
      t.integer :pay_type
      t.datetime :payed_at
      t.integer :pay_state
      t.datetime :deleted_at
      t.string :memo

      t.timestamps null: false
    end
    add_index :orders, :order_no, unique: true
    add_index :orders, :company_id
    add_index :orders, :merchant_id
    add_index :orders, :shop_id
    add_index :orders, :device_id
    add_index :orders, :pay_type
    add_index :orders, :pay_state
  end
end
