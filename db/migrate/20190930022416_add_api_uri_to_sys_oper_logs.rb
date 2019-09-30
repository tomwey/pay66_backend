class AddApiUriToSysOperLogs < ActiveRecord::Migration
  def change
    add_column :sys_oper_logs, :api_uri, :string
  end
end
