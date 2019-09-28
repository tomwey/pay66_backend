class AddBalanceAndEarnAndRoleToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :balance, :integer, default: 0
    add_column :accounts, :earn, :integer, default: 0
    add_column :accounts, :role, :integer
  end
end
