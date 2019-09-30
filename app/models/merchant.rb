class Merchant < ActiveRecord::Base
  def self.roles
    l1 = SiteConfig.merch_roles.split(',')
    arr1 = []
    l1.each do |c|
      l2 = c.split(':')
      arr1 << { label: l2[0], value: l2[1] }
    end
    arr1
  end
end
