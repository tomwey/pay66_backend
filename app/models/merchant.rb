class Merchant < ActiveRecord::Base
  validates :name, :brand, :logo, :mobile, :license_no, :license_image, :address, presence: true
  
  has_many :accounts, class_name: 'MerchAccount', dependent: :destroy
  belongs_to :company
  
  def self.roles
    l1 = SiteConfig.merch_roles.split(',')
    arr1 = []
    l1.each do |c|
      l2 = c.split(':')
      arr1 << { label: l2[0], value: l2[1] }
    end
    arr1
  end
  
  before_create :gen_random_id
  def gen_random_id
    begin
      self.id = SecureRandom.random_number(100000..1000000)
    end while self.class.exists?(:id => id)
  end
  
  def auth_qrcodes
    arr = []
    company.app_configs.each do |config|
      name = config.platform_name + '授权'
      redirect_url = (config.redirect_uri || SiteConfig.auth_redirect_uri) + "?cid=#{self.company_id}&p=#{config.platform}&mid=#{self.id}"
      auth_url = config.app_auth_url + "#{Rack::Utils.escape(redirect_url)}"
      arr << { name: name, url: auth_url, qrcode: "#{SiteConfig.create_qrcode_url}?text=#{Rack::Utils.escape(auth_url)}" }
    end
    arr
  end
  
  def _balance=(val)
    if val.present?
      self.balance = (val.to_f * 100).to_i
    end
  end
  
  def _balance
    '%.2f' % (self.balance / 100.0)
  end
  
  def logo_url
    if logo.blank?
      ''
    else
      asset = Attachment.find_by(id: logo)
      if asset.blank?
        ''
      else
        asset.data.url
      end
    end
  end
  
  def license_image_url
    if license_image.blank?
      ''
    else
      asset = Attachment.find_by(id: license_image)
      if asset.blank?
        ''
      else
        asset.data.url
      end
    end
  end
  
  # 关联管理员账号
  def admin=(val)
    unless val.is_a? Hash
      return
    end
    
    # asset = Attachment.find_by(id: val['avatar'])
    # avatar_url = nil
    # if asset
    #   avatar_url = asset.data.url
    # end
    if self.new_record?
      self.accounts.build(name: val['name'], avatar: val['avatar'], mobile: val['mobile'], password: val['password'], is_admin: true, company_id: self.company_id)
    else
      account = self.accounts.where(is_admin: true, id: val['id']).first
      account.name = val['name']
      account.avatar = val['avatar']
      account.save!
    end
  end
  
  def permit_params
    ['name', 'brand', 'logo', 'license_no', 'license_image', 'mobile', 'address', '_balance', 'memo', 'admin', 'alipay_pid']
  end
  
end
