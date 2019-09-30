class Account < ActiveRecord::Base
  has_secure_password
  validates :mobile, presence: true, format: { with: /\A1[3|4|5|6|8|7|9][0-9]\d{4,8}\z/ }
  validates :name, presence: true
  validates_uniqueness_of :mobile, scope: :company_id
  validates :password, length: { minimum: 6 }, allow_nil: true
  
  belongs_to :company
  belongs_to :parent, class_name: 'Account', foreign_key: :pid
  
  has_and_belongs_to_many :roles
  has_many :permissions, class_name: 'FuncAction', through: :roles
  
  mount_uploader :avatar, AvatarUploader
  
  before_create :generate_id_and_private_token
  def generate_id_and_private_token
    begin
      self.id = SecureRandom.random_number(100000..1000000)
    end while self.class.exists?(:id => id)
    self.private_token = SecureRandom.uuid.gsub('-', '')
  end
  
  def can?(resource_class, action_name) 
    if self.is_admin
      return true
    end
        
    return true
  end
  
  def permit_params
    ['name', 'mobile', 'password', 'password2', 'role', 'pid']
  end
  
  def role_name
    r = Company.roles.select { |e| e[:value].to_i == role }.first
    if r
      r[:label]
    else
      nil
    end
  end
  
end
