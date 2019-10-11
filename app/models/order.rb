class Order < ActiveRecord::Base
  validates :money, :device_id, :pay_type, presence: true
  validates_uniqueness_of :order_no
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
    if self.order_no.blank?
      begin
        self.order_no = Time.now.to_s(:number)[2,6] + (Time.now.to_i - Date.today.to_time.to_i).to_s + Time.now.nsec.to_s[0,6]
      end while self.class.exists?(:order_no => order_no)
    end
  end
  
  before_create :populate_data
  def populate_data
    if self.device
      self.shop_id = self.device.shop_id
      self.merchant_id = self.device.merchant_id
      # self.pay_type = self.device.platform
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
    
    code,res = Alipay::Pay.pay2merch(app_config.app_id, ma.app_auth_token, self.order_no, auth_code, self.title || "付款#{(self.money - (self.discount_money || 0))/100.0}元", ma.userid, self.money, self.discount_money || 0, "#{self.operator.try(:id)}", "#{self.shop.try(:id)}", "#{self.device.serial_no}",app_config.sys_pid, app_config.private_key, app_config.pub_key)
    if code == 0
      self.payed_at = Time.zone.now
      self.buyer_id = res['buyer_logon_id']
      self.pay_state = 1 # 支付成功 1 成功 2 
      self.save!
    elsif code == 40004 # 支付失败
      self.pay_state = 0
      self.error_memo = "code:#{code},sub_code:#{res['sub_code']},sub_msg:#{res['sub_msg']}"
      self.save!
    elsif code == 10003 # 等待用户付款
      self.alipay_loop_query_trade(app_config.app_id,ma.app_auth_token,app_config.private_key,app_config.pub_key)
    elsif code == 20000 # 未知异常
      # code2,res = Alipay::Pay.query_pay(app_config.app_id,
      #                 ma.app_auth_token,self.order_no,app_config.private_key,app_config.pub_key)
      self.pay_state = 0
      self.error_memo = "code:#{code},sub_code:#{res['sub_code']},sub_msg:#{res['sub_msg']}"
      self.save!
    end
  end
  
  def alipay_loop_query_trade(app_id, app_auth_token, prv_key, pub_key)
    sleep 5
    code,res = Alipay::Pay.query_pay(app_id,app_auth_token,self.order_no,prv_key,pub_key)
    if res['trade_status'] == 'WAIT_BUYER_PAY'
      count = $redis.get "retry_#{self.order_no}"
      count = (count || 1).to_i
      if count >= 10
        # 取消交易
        $redis.del "retry_#{self.order_no}"
        code2,res2 = Alipay::Pay.cancel_pay(app_id,app_auth_token,self.order_no,prv_key,pub_key)
        if code2 == 0
          self.pay_state = 2
          self.save!
        else
          self.pay_state = 0
          self.error_memo = "code:#{code2},sub_code:#{res2['sub_code']},sub_msg:#{res2['sub_msg']}"
          self.save!
        end
      else
        count = count + 1
        $redis.set "retry_#{self.order_no}", count
        # 等5秒再次查询
        self.alipay_loop_query_trade(app_id, app_auth_token, prv_key, pub_key)
      end
    elsif res['trade_status'] == 'TRADE_CLOSED'
      self.pay_state = 2
      self.save!
    elsif res['trade_status'] == 'TRADE_SUCCESS'
      self.pay_state = 1
      self.payed_at = Time.zone.now
      self.save!
    else
      self.pay_state = 0
      self.error_memo = "code:#{code},sub_code:#{res['sub_code']},sub_msg:#{res['sub_msg']}"
      self.save!
    end
  end
  
  def send_wx_pay(auth_code)
    
  end
  
  def pay_type_name
    case pay_type
    when 1 then '支付宝'
    when 2 then '微信'
    else ''
    end
  end
  
  def pay_state_name
    case pay_state
    when 0 then '交易失败'
    when 1 then '交易成功'
    when 2 then '交易关闭'
    else ''
    end
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
  
  def _auth_code=(val)
    prefix = val[0...2]
    prefix = prefix.to_i
    if prefix >= 25 and prefix <= 30
      self.pay_type = 1 # 支付宝
    elsif prefix >= 10 and prefix <= 15
      self.pay_type = 2 # 微信
    end
    self.auth_code = val
  end
  
  def permit_params
    ['title', '_auth_code', 'device_id', '_money', 'operator_id', '_discount_money', 'memo']
  end
end
