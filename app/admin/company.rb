ActiveAdmin.register Company do
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
permit_params :name, :brand, :logo, :mobile, :license_no, :license_image, :address, :memo, :opened, :vip_expired_at, :_balance, accounts_attributes: [:id, :name, :avatar, :mobile, :password, :is_admin, :opened, :_destroy], app_configs_attributes: [:id, :app_id, :sys_pid, :platform, :application_type, :app_gateway, :redirect_uri, :state, :private_key, :pub_key, :aes_key, :auth_url, :merch_pid, :_destroy]
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

index do
  selectable_column
  column 'ID', :id
  column :brand
  column :logo do |o|
    image_tag o.logo.url(:large)
  end
  column :name
  column :mobile
  column :license_no
  column :license_image do |o|
    image_tag o.license_image.url
  end
  column :address
  column :opened
  column :vip_expired_at
  column 'at', :created_at
  actions
end

form do |f|
  f.semantic_errors
  f.inputs '基本信息' do
    f.input :name
    f.input :brand
    f.input :logo
    f.input :license_no
    f.input :license_image
    f.input :mobile
    f.input :address
    f.input :vip_expired_at, as: :string
    f.input :_balance, as: :number, label: '余额(元)'
    f.input :opened
    f.input :memo
  end
  f.inputs '超级管理员账号' do
    f.has_many :accounts, allow_destroy: true, heading: '' do |item_form|
      item_form.input :name, as: :string, placeholder: "例如：2018-10-10"
      item_form.input :avatar
      item_form.input :mobile
      item_form.input :password, placeholder: '至少6位'
      item_form.input :opened
      item_form.input :is_admin
    end
  end
  f.inputs '应用配置' do
    f.has_many :app_configs, allow_destroy: true, heading: '' do |item_form|
      item_form.input :app_id
      item_form.input :sys_pid
      item_form.input :platform, as: :select, collection: [['支付宝', 1], ['微信', 2]]
      item_form.input :application_type
      item_form.input :app_gateway
      item_form.input :redirect_uri
      item_form.input :auth_url
      item_form.input :state
      item_form.input :private_key, as: :text, rows: 6
      item_form.input :pub_key, as: :text, rows: 6
      item_form.input :aes_key, label: 'AES密钥'
    end
  end
  
  actions
end

end
