module API
  module V1
    module Entities
      class Base < Grape::Entity
        format_with(:null) { |v| v.blank? ? "" : v }
        format_with(:chinese_date) { |v| v.blank? ? "" : v.strftime('%Y-%m-%d') }
        format_with(:chinese_datetime) { |v| v.blank? ? "" : v.strftime('%Y-%m-%d %H:%M:%S') }
        format_with(:month_date_time) { |v| v.blank? ? "" : v.strftime('%m月%d日 %H:%M') }
        format_with(:money_format) { |v| v.blank? ? 0.00 : ('%.2f' % v) }
        format_with(:rmb_format) { |v| v.blank? ? 0.00 : ('%.2f' % (v / 100.00)) }
        expose :id
        expose :created_at, as: :create_time, format_with: :chinese_datetime
        # expose :created_at, format_with: :chinese_datetime
      end # end Base
      
      class UserBase < Base
        expose :uid, as: :id
        expose :private_token, as: :token
        expose :is_authed do |model, opts|
          model.idcard.present?
        end
      end
      
      # 用户基本信息
      # class UserProfile < UserBase
      #   # expose :uid, format_with: :null
      #   expose :mobile, format_with: :null
      #   expose :nickname do |model, opts|
      #     model.format_nickname
      #   end
      #   expose :avatar do |model, opts|
      #     model.real_avatar_url
      #   end
      #   expose :nb_code, as: :invite_code
      #   expose :earn, format_with: :money_format
      #   expose :balance, format_with: :money_format
      #   expose :today_earn, format_with: :money_format
      #   expose :wx_id, format_with: :null
      #   unexpose :private_token, as: :token
      # end
      
      # 用户资料
      class UserProfile < UserBase
        unexpose :private_token, as: :token
        expose :name, :idcard, :mobile
        expose :format_nickname, as: :nickname
        # expose :total_salary_money, as: :total_money, format_with: :money_format
        # expose :sent_salary_money, as: :payed_money, format_with: :money_format
        # expose :senting_salary_money, as: :unpayed_money, format_with: :money_format
      end
      # 用户详情
      class User < UserBase
        expose :uid, as: :id
        expose :mobile, format_with: :null
        expose :nickname do |model, opts|
          model.format_nickname
        end
        expose :avatar do |model, opts|
          model.format_avatar_url
        end
        expose :balance, format_with: :rmb_format
        expose :vip_expired_at, as: :vip_time, format_with: :chinese_date
        expose :left_days, as: :vip_status
        expose :qrcode_url
        expose :portal_url
        unexpose :private_token, as: :token
        expose :wx_bind
        expose :qq_bind
        
        # expose :vip_expired_at, as: :vip_time, format_with: :chinese_date
        # expose :left_days do |model, opts|
        #   model.left_days
        # end
        # expose :private_token, as: :token, format_with: :null
      end
      
      class SimpleUser < Base
        expose :uid, as: :id
        expose :mobile, format_with: :null
        expose :nickname do |model, opts|
          model.format_nickname
        end
        expose :avatar do |model, opts|
          model.format_avatar_url
        end
      end
      
      class SimplePage < Base
        expose :title, :slug
      end
      
      class Page < SimplePage
        expose :title, :body
      end
      
      class SimpleCategory < Base
        expose :name, :sort, :memo
      end
      
      class Category < SimpleCategory
        expose :parent, using: API::V1::Entities::SimpleCategory
      end
      
      class SimpleCompany < Base
        expose :brand, :name
        # expose :logo do |model, opts|
        #   model.logo.blank? ? '' : model.logo.url(:big)
        # end
        expose :logo_url
        expose :logo_url, as: :logo
        expose :logo_url, as: :logo_id
        expose :theme do |model, opts|
          '#' + "#{model.id}"
        end
        expose :slogan do |model, opts|
          model.try(:slogan) || ""
        end
        expose :services do |model, opts|
          model.try(:services) || ""
        end
      end
      
      class SimpleAccount < Base
        expose :mobile, format_with: :null
        expose :name, format_with: :null
        expose :avatar do |model, opts|
          model.avatar.blank? ? '' : model.avatar.url(:big)
        end
        expose :private_token, as: :token
        expose :opened
        expose :role
        expose :role_name
        
      end
      
      class Company < SimpleCompany
        # expose :balance, format_with: :rmb_format
        # expose :_balance, :name, :mobile, :address, :opened
        # expose :vip_time, format_with: :chinese_date do |model,opts|
        #   model.parent ? model.parent.vip_expired_at : model.vip_expired_at
        # end
        # expose :left_days do |model,opts|
        #   model.parent ? model.parent.left_days : model.left_days
        # end
        expose :license_no, :license_image_url
        expose :license_image_url, as: :license_image_id
        # expose :admin, using: API::V1::Entities::SimpleAccount do |model,opts|
        #   model.accounts.where(is_admin: true).first
        # end
      end
      
      class SimpleMerchAccount < Base
        expose :mobile, format_with: :null
        expose :name, format_with: :null
        expose :avatar_url, :avatar
        expose :private_token, as: :token
        expose :opened
        expose :role
        expose :role_name
      end
      
      class SimpleMerchant < Base
        expose :brand, :name, :mobile
        # expose :logo do |model, opts|
        #   model.logo.blank? ? '' : model.logo.url(:big)
        # end
        expose :logo_url, :logo
        expose :theme do |model, opts|
          '#' + "#{model.id}"
        end
        expose :slogan do |model, opts|
          model.try(:slogan) || ""
        end
        expose :services do |model, opts|
          model.try(:services) || ""
        end
      end
      
      class Merchant < SimpleMerchant
        expose :portal_url do |model,opts|
          ""
        end
        expose :auth_qrcodes, :alipay_pid
        expose :license_no, :license_image, :license_image_url, :address, :opened, :memo
        expose :admin, using: API::V1::Entities::SimpleMerchAccount do |model,opts|
          model.accounts.where(is_admin: true).first
        end
      end
      
      class MerchAccount < SimpleMerchAccount
        expose :is_admin
        expose :last_login_at, format_with: :chinese_datetime
        expose :last_login_ip, :login_count, :merchant_id
        expose :company, using: API::V1::Entities::Company
        expose :merchant, using: API::V1::Entities::SimpleMerchant
        unexpose :private_token, as: :token
        # expose :token_md5 do |model,opts|
        #   Digest::MD5.hexdigest(model.private_token)
        # end
      end
      
      class Shop < Base
        expose :name, :_type, :scope, :phone, :outer_images, :inner_images, :memo, :merchant_id, :address
        expose :merchant, using: API::V1::Entities::SimpleMerchant
        expose :type_name do |model,opts|
          model._type == 1 ? '直营' : '加盟'
        end
        expose :category, using: API::V1::Entities::Category
      end
      
      class Device < Base
        expose :device_type, :serial_no, :model, :memo, :opened, :run_mode, :sdk_version, :app_version
        expose :shop_id, :merchant_id
        expose :shop, using: API::V1::Entities::Shop
        expose :merchant, using: API::V1::Entities::SimpleMerchant
        expose :last_heartbeat_at, format_with: :chinese_datetime
      end
      
      class SimpleTag < Base
        expose :name, :memo, :opened
      end
      
      class Tag < SimpleTag
        expose :name, :memo, :opened
      end
      
      class Account < SimpleAccount
        expose :is_admin
        expose :last_login_at, format_with: :chinese_datetime
        expose :last_login_ip
        expose :company, using: API::V1::Entities::Company
        unexpose :private_token, as: :token
        expose :token_md5 do |model,opts|
          Digest::MD5.hexdigest(model.private_token)
        end
        
        expose :parent, using: API::V1::Entities::SimpleAccount
        # expose :permissions, using: API::V1::Entities::Permission
      end
      
      
      
      class Attachment < Base
        expose :content_type do |model, opts|
          model.data.content_type
        end
        expose :url do |model, opts|
          model.data.url
        end
        expose :filename do |model,opts|
          model.old_filename || model.data_file_name
        end
        expose :filesize do |model,opts|
          model.data_file_size
        end
        expose :width, :height
      end
      
      class TradeLog < Base
        expose :uniq_id, as: :id, format_with: :null
        expose :title
        expose :money, format_with: :rmb_format
        expose :created_at, as: :time, format_with: :month_date_time
      end
      
      # 收益明细
      class EarnLog < Base
        expose :title
        expose :earn
        expose :unit
        expose :created_at, as: :time, format_with: :chinese_datetime
      end
      
      # 消息
      class Message < Base
        expose :title do |model, opts|
          model.title || '系统公告'
        end#, format_with: :null
        expose :content, as: :body
        expose :created_at, format_with: :chinese_datetime
      end
      
      # 提现
      class Withdraw < Base
        expose :bean, :fee
        expose :total_beans do |model, opts|
          model.bean + model.fee
        end
        expose :pay_type do |model, opts|
          if model.account_type == 1
            "微信提现"
          elsif model.account_type == 2
            "支付宝提现"
          else
            ""
          end
        end
        expose :state_info, as: :state
        expose :created_at, as: :time, format_with: :chinese_datetime
        # expose :user, using: API::V1::Entities::Author
      end
      
      class Banner < Base
        expose :uniq_id, as: :id
        expose :image do |model, opts|
          model.image.url(:large)
        end
        expose :link, format_with: :null, if: proc { |o| o.is_link? }
        # expose :loan_product, as: :loan, using: API::V1::Entities::LoanProduct, if: proc { |o| o.is_loan_product? }
        expose :page, using: API::V1::Entities::SimplePage, if: proc { |o| o.is_page? }
        expose :view_count, :click_count
      end
      
    end
  end
end