class AddMerchAccountIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :merch_account_id, :integer
    add_index :orders, :merch_account_id
  end
end
