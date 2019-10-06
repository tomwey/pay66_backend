class Shop < ActiveRecord::Base
  validates :name, :_type, :outer_images, :scope, presence: true
  belongs_to :merchant
  belongs_to :category, foreign_key: :scope
  
  before_create :generate_id
  def generate_id
    begin
      self.id = SecureRandom.random_number(100000..1000000)
    end while self.class.exists?(:id => id)
  end
  
  def permit_params
    ['name', '_type', 'outer_images', 'scope', 'merchant_id', 'inner_images', 'phone', 'address', 'memo']
  end
end
