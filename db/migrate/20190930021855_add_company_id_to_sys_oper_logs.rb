class AddCompanyIdToSysOperLogs < ActiveRecord::Migration
  def change
    add_column :sys_oper_logs, :company_id, :integer
    add_index :sys_oper_logs, :company_id
  end
end
