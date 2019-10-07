class Membership < ActiveRecord::Base
  validates :user_id, :merchant_id, presence: true
  validates_uniqueness_of :user_id, scope: [:company_id, :merchant_id, :deleted_at]
  belongs_to :user
  belongs_to :merchant
end
