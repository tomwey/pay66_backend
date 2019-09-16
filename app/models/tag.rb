class Tag < ActiveRecord::Base
  validates :name, :company_id, presence: true
  validates_uniqueness_of :name, scope: :company_id
  
  belongs_to :company
  has_and_belongs_to_many :articles
  
  def permit_params
    ['name', 'memo']
  end
end
