class AddSloganAndServicesToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :slogan, :string
    add_column :companies, :services, :string
  end
end
