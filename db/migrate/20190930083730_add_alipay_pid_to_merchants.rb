class AddAlipayPidToMerchants < ActiveRecord::Migration
  def change
    add_column :merchants, :alipay_pid, :string
  end
end
