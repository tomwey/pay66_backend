class MerchAccount < ActiveRecord::Base
  has_secure_password
  validates :mobile, presence: true, format: { with: /\A1[3|4|5|6|8|7|9][0-9]\d{4,8}\z/ }
  validates :name, presence: true
  validates_uniqueness_of :mobile, scope: [:company_id, :merchant_id, :deleted_at]
  validates :password, length: { minimum: 6 }, allow_nil: true
  
  belongs_to :company
  belongs_to :merchant
  
  def role_name
    r = Merchant.roles.select { |e| e[:value].to_i == role }.first
    if r
      r[:label]
    else
      nil
    end
  end
  
  def avatar_url
    asset = Attachment.find_by(id: avatar)
    if asset.blank?
      ''
    else
      asset.data.url
    end
  end
  
  def permit_params
    ['name', 'mobile', 'password', 'password2', 'role', 'memo', 'avatar', 'merchant_id']
  end
  
end
