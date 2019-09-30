class CreateAppConfigs < ActiveRecord::Migration
  def change
    create_table :app_configs do |t|
      t.integer :company_id
      t.string :app_id
      t.string :sys_pid
      t.string :platform
      t.string :application_type
      t.string :app_gateway
      t.string :redirect_uri
      t.string :state
      t.string :private_key
      t.string :pub_key
      t.string :aes_key

      t.timestamps null: false
    end
    add_index :app_configs, :company_id
  end
end
