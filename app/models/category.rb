class Category < ActiveRecord::Base
  validates :name, presence: true
  validates_uniqueness_of :name, scope: :company_id
  belongs_to :parent, class_name: 'Category', foreign_key: :pid
  
  def permit_params
    ['name', 'pid', 'sort', 'memo']
  end
  
end
