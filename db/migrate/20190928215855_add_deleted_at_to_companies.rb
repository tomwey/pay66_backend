class AddDeletedAtToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :deleted_at, :datetime
  end
end
