class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.integer :company_id
      t.integer :pid
      t.datetime :deleted_at
      t.integer :sort, default: 0
      t.string :memo

      t.timestamps null: false
    end
    add_index :categories, :company_id
    add_index :categories, :pid
  end
end
