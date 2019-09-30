class AppConfig < ActiveRecord::Base
  validates :app_id, :sys_pid, :platform, presence: true
  validates_uniqueness_of :app_id, scope: [:company_id, :platform]
  belongs_to :company
end
