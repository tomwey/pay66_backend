class AddLoginCountToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :login_count, :integer, default: 0
    add_column :merch_accounts, :login_count, :integer, default: 0
  end
end
