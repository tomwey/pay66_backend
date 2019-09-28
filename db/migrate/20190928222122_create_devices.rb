class CreateDevices < ActiveRecord::Migration
  def change
    create_table :devices do |t|
      t.integer :company_id
      t.integer :merchant_id
      t.integer :shop_id
      t.string :device_type, null: false
      t.string :serial_no, null: false
      t.string :model
      t.string :run_mode
      t.string :sdk_version
      t.string :app_version
      t.datetime :last_heartbeat_at
      t.boolean :opened, default: true
      t.datetime :deleted_at
      t.string :memo

      t.timestamps null: false
    end
    add_index :devices, :company_id
    add_index :devices, :merchant_id
    add_index :devices, :shop_id
    add_index :devices, :serial_no
  end
end
