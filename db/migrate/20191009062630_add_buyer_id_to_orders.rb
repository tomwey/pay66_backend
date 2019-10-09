class AddBuyerIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :buyer_id, :string
    add_index :orders, :buyer_id
  end
end
