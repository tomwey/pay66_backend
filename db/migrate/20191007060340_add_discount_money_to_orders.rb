class AddDiscountMoneyToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :discount_money, :integer
  end
end
