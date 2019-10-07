class Order < ActiveRecord::Base
  validates :money, :device_id, :pay_type, presence: true
  belongs_to :company
  belongs_to :merchant
  belongs_to :shop
  belongs_to :device
  belongs_to :operator, class_name: 'MerchAccount', foreign_key: :merch_account_id
  
  attr_accessor :auth_code
  
  validate :check_discount_money
  def check_discount_money
    if self.discount_money && self.discount_money > self.money
      errors.add(:base, '优惠金额不能大于总金额')
      return false
    end
  end
  
  before_create :generate_order_no
  def generate_order_no
    begin
      self.order_no = Time.now.to_s(:number)[2,6] + (Time.now.to_i - Date.today.to_time.to_i).to_s + Time.now.nsec.to_s[0,6]
    end while self.class.exists?(:order_no => order_no)
  end
  
  before_create :populate_data
  def populate_data
    if self.device
      self.shop_id = self.device.shop_id
      self.merchant_id = self.device.merchant_id
      # self.pay_type = self.device.platform
    end
    prefix = self.auth_code[0...2]
    prefix = prefix.to_i
    if prefix >= 25 and prefix <= 30
      self.pay_type = 1 # 支付宝
    elsif prefix >= 10 and prefix <= 15
      self.pay_type = 2 # 微信
    end
  end
  
  after_create :do_pay
  def do_pay
    OrderPayJob.perform_later(self.id, self.auth_code)
  end
  
  def send_to_pay!(auth_code)
    if self.pay_type == 1
      self.send_alipay(auth_code)
    elsif self.pay_type == 2
      self.send_wx_pay(auth_code)
    end
  end
  
  def send_alipay(auth_code)
    app_config = company.app_configs.where(platform: self.pay_type).first
    if app_config.blank?
      return
    end
    # app_id,
    # app_auth_token,
    # out_trade_no,
    # buyer_auth_code,
    # subject,
    # seller_id,
    # total_money,
    # discount_money,
    # operator_id,
    # store_id,
    # terminal_id,
    # isv_id,
    # prv_key,
    # ali_pub_key
    ma = MerchAuth.where(company_id: self.company_id, merchant_id: self.merchant_id, provider: '1', auth_app_id: app_config.app_id).first
    return if ma.blank?
    
    code,res = Alipay::Pay.pay2merch(app_config.app_id, ma.app_auth_token, self.order_no, auth_code, self.title || "付款#{(self.money - (self.discount_money || 0))/100.0}元", ma.userid, self.money, self.discount_money || 0, "#{self.operator.id}", "#{self.shop.id}", "#{self.device.serial_no}",app_config.sys_pid, app_config.private_key, app_config.pub_key)
    if code == 0
      self.payed_at = Time.zone.now
      self.pay_state = 1 # 支付成功
      self.save!
    elsif code == 40004 # 支付失败
      self.pay_state = 0
      self.save!
    elsif code == 10003 # 等待用户付款
    elsif code == 20000 # 未知异常
      code2,res = Alipay::Pay.query_pay(app_config.app_id,
                      ma.app_auth_token,self.order_no,app_config.private_key,app_config.pub_key)
    end
  end
  
  def send_wx_pay(auth_code)
    
  end
  
  def _money=(val)
    if val.present?
      self.money = (val.to_f * 100).to_i
    end
  end
  
  def _money
    (self.money / 100.0)
  end
  
  def _discount_money=(val)
    if val.present?
      self.discount_money = (val.to_f * 100).to_i
    end
  end
  
  def _discount_money
    if self.discount_money.blank?
      nil
    else
      (self.discount_money / 100.0)
    end
  end
  
  def operator_id=(val)
    self.merch_account_id = val
  end
  
  def operator_id
    self.merch_account_id
  end
  
  def permit_params
    ['title', 'auth_code', 'device_id', '_money', 'operator_id', '_discount_money', 'memo']
  end
end
