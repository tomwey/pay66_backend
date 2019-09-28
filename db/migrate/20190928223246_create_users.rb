class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :company_id
      t.string :mobile
      t.string :name
      t.string :avatar
      t.string :private_token
      t.boolean :opened, default: true
      t.datetime :deleted_at

      t.timestamps null: false
    end
    add_index :users, :company_id
    add_index :users, :private_token, unique: true
  end
end
