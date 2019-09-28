class AddPidAndDeletedAtToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :pid, :integer
    add_index :accounts, :pid
    add_column :accounts, :deleted_at, :datetime
  end
end
