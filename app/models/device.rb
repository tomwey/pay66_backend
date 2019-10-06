class Device < ActiveRecord::Base
  validates :device_type, :serial_no, :shop_id, :merchant_id, presence: true
  belongs_to :shop
  belongs_to :merchant
  
  def permit_params
    ['merchant_id', 'shop_id', 'device_type', 'serial_no', 'model', 'run_mode', 'sdk_version', 'app_version', 'memo']
  end
end
