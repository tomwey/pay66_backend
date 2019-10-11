require 'rest-client'
module API
  module V1
    class AppAPI < Grape::API
      helpers API::SharedParams
      resource :app, desc: "机构配置相关的接口" do
        desc "获取配置"
        params do
          requires :cid, type: Integer, desc: '机构ID'
        end
        get :configs do
          oid = params[:cid]
          @company = Company.find_by(id: oid)
          if @company.blank? or @company.deleted_at.present?
            return render_error(4004, '机构不存在')
          end
          render_json(@company, API::V1::Entities::SimpleCompany)
        end # end get configs
      end # end resource
      
      resource :order, desc: '订单支付接口' do
        desc "订单支付接口"
        params do
          optional :order_no,  type: String, desc: '订单号'
          requires :money,     type: Float,  desc: '订单金额，单位为元'
          requires :auth_code, type: String, desc: '付款码'
          requires :sn,        type: String, desc: '设备序列号'
          optional :type,      type: String, desc: '支付类型，C 表示扫码，F 表示扫脸'
        end
        get :pay do
          status 200
          device = Device.find_by(serial_no: params[:sn])
          if device.blank?
            return render_error(4004, '设备不存在')
          end
          
          order = Order.create!(company_id: device.company_id, title: "一笔新订单", _auth_code: params[:auth_code], device_id: device.id, _money: params[:money], order_no: params[:order_no])
          
          render_json(order, API::V1::Entities::Order)
        end # end post pay
      end # end resource
    end
  end
end