class User < ActiveRecord::Base
  mount_uploader :avatar, AvatarUploader
  
  # has_one :profile, dependent: :destroy
  # has_many :salaries, dependent: :destroy
  
  # scope :authed, -> { where('bank_no is not null') }
  # scope :unauthed, -> { where(bank_no: nil) }
  
  # belongs_to :channel, foreign_key: :from_chn_id
  
  before_create :generate_uid_and_private_token
  def generate_uid_and_private_token
    begin
      n = rand(10)
      if n == 0
        n = 8
      end
      self.uid = (n.to_s + SecureRandom.random_number.to_s[2..8]).to_i
    end while self.class.exists?(:uid => uid)
    self.private_token = SecureRandom.uuid.gsub('-', '')
  end
  
  def hack_mobile
    return "" if self.mobile.blank?
    hack_mobile = String.new(self.mobile)
    hack_mobile[3..6] = "****"
    hack_mobile
  end
  
  def auth_profile
    @profile ||= AuthProfile.where(user_id: self.uid, provider: 'qq').first || AuthProfile.where(user_id: self.uid, provider: 'wechat').first
  end
  
  def format_nickname
    auth_profile.try(:nickname) || self.nickname || hack_mobile || "ID:#{self.uid}"
    # @ud ||= UserDevice.where(uid: self.uid).first
    # return @ud.try(:uname) || "ID:#{self.uid}"
  end
  
  def format_avatar_url
    # if avatar.present?
    #   avatar.url(:large)
    # else
    #   ''
    # end
    if auth_profile
      auth_profile.try(:headimgurl)
    else
      if avatar.present?
        avatar.url(:large)
      else
        ''
      end
    end
  end
  
  def open_redpack(hb)
    if hb.is_cash?
      # 现金红包如果还没被抢完，那么重新开启红包，会从用户余额扣除来支付该红包剩下的费用
      if hb.left_money > 0 # 红包还未领完
        if self.balance < left_money
          return '余额不足，请先充值'
        else
          self.create_redpack_operation!(hb, 'open', true)
          return nil
        end
      else
        self.create_redpack_operation!(hb, 'open',false)
        return nil
      end
    else
      # 如果是消费红包，直接进行开启功能
      self.create_redpack_operation!(hb, 'open', false)
      return nil
    end
  end
  
  def close_redpack(hb)
    if hb.is_cash?
      # 现金红包如果还没被抢完，那么关闭红包，会将剩余红包金额存入余额
      if hb.left_money > 0 # 红包还未领完
        self.create_redpack_operation!(hb, 'close', true)
        return nil
      else
        self.create_redpack_operation!(hb, 'close',false)
        return nil
      end
    else 
      # 如果是消费红包，直接进行开启功能
      self.create_redpack_operation!(hb, 'close', false)
      return nil
    end
  end
  
  def create_redpack_operation!(hb, action, has_trade)
    hb.opened = action == 'open'
    hb.save!
    
    UserRedpackOperation.create!(user_id: self.uid, redpack_id: hb.uniq_id, action: action)
    if has_trade
      money = action == 'open' ? -hb.left_money : hb.left_money
      TradeLog.create!(user_id: self.uid, 
                       title: I18n.t(action) + '红包', 
                       money: money, 
                       action: "#{action}_hb",
                       tradeable_type: hb.class,
                       tradeable_id: hb.uniq_id
                       )
    end
  end
  
  def total_salary_money
    @mm ||= salaries.sum(:money)
  end
  
  def sent_salary_money
    @m2 ||= salaries.where.not(payed_at: nil).sum(:money)
  end
  
  def senting_salary_money
    @money ||= salaries.where(payed_at: nil, state: 'approved').sum(:money)
  end
  
  def wx_bind
    AuthProfile.where(user_id: self.uid, provider: 'wechat').count > 0
  end
  
  def qq_bind
    AuthProfile.where(user_id: self.uid, provider: 'qq').count > 0
  end
  
  def left_days
    if self.vip_expired_at.blank?
      '普通账号'
    elsif self.vip_expired_at < Time.zone.now
      seconds = (Time.zone.now - self.vip_expired_at).to_i
      "会员账号, 过期#{(seconds.to_f / (24 * 3600) + 1).to_i}天"
    else
      seconds = (self.vip_expired_at - Time.zone.now).to_i
      "会员账号, 还剩#{(seconds.to_f / (24 * 3600) + 1).to_i}天到期"
    end
  end
  
  def qrcode_url
    "#{SiteConfig.main_server}/qrcode?text=#{self.portal_url}"
  end
  
  def portal_url
    ShortUrl.sina("#{SiteConfig.front_url}/?uid=#{self.uid}")
  end
  
  def vip_expired?
    return (self.vip_expired_at.blank? or self.vip_expired_at < Time.zone.now)
  end
  
  def active_vip_card!(card)
    count = card.month
    
    time = self.vip_expired_at || Time.zone.now
    self.vip_expired_at = time + count.month
    self.save!
    
    card.actived_user_id = self.uid
    card.actived_at = Time.zone.now
    card.save!
    
  end
  
  def block!
    self.verified = false
    self.save!
  end
  
  def unblock!
    self.verified = true
    self.save!
  end
  
end
