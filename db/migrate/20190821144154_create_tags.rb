class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.integer :company_id, null: false, index: true
      t.string :memo
      t.boolean :opened, default: true
      t.datetime :deleted_at

      t.timestamps null: false
    end
  end
end
