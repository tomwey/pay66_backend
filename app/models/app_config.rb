class AppConfig < ActiveRecord::Base
  validates :app_id, :sys_pid, :platform, presence: true
  validates_uniqueness_of :app_id, scope: [:company_id, :platform]
  belongs_to :company
  
  def platform_name
    I18n.t("common.ac_#{self.platform}")
  end
  
  def app_auth_url
    case platform.to_i
    when 1 then "https://openauth.alipay.com/oauth2/appToAppBatchAuth.htm?app_id=#{self.app_id}&application_type=#{self.application_type}&redirect_uri="
    when 2 then ""
    else ""
    end
  end
end
