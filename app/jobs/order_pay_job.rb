class OrderPayJob < ActiveJob::Base
  queue_as :scheduled_jobs

  def perform(order_id, auth_code)
    order = Order.find_by(id: order_id)
    return if order.blank?
    
    order.send_to_pay!(auth_code)
    # if order.pay_type == 1
    #   # 支付宝
    #   order.do_alipay!
    # elsif order.pay_type == 2
    #   # 微信
    #   order.do_wx_pay!
    # end
    
  end
  
end
