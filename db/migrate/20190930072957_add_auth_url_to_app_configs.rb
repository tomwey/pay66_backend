class AddAuthUrlToAppConfigs < ActiveRecord::Migration
  def change
    add_column :app_configs, :auth_url, :string
  end
end
