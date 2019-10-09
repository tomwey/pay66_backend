class AddErrorMemoToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :error_memo, :string
  end
end
