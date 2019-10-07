require 'rest-client'
require 'openssl'
require 'base64'
module Alipay
  class Pay
    # 买家向卖家付钱
    def self.pay2merch(
      app_id,
      app_auth_token,
      out_trade_no,
      buyer_auth_code,
      subject,
      seller_id,
      total_money,
      discount_money,
      operator_id,
      store_id,
      terminal_id,
      isv_id,
      prv_key,
      ali_pub_key
    )
      params = {
        app_id: app_id || SiteConfig.alipay_app_id,
        method: 'alipay.trade.pay',
        charset: 'utf-8',
        sign_type: 'RSA2',
        timestamp: Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
        app_auth_token: app_auth_token,
        version: '1.0',
        biz_content: {
          out_trade_no: out_trade_no || Time.now.to_i.to_s,
          scene: 'bar_code',
          auth_code: buyer_auth_code,
          subject: subject,
          seller_id: seller_id,
          total_amount: total_money / 100.0,
          discountable_amount: (discount_money || 0) / 100.0,
          operator_id: operator_id,
          store_id: store_id,
          terminal_id: terminal_id,
          timeout_express: '2m',
          extend_params: {
            sys_service_provider_id: isv_id
          }.to_json
        }.to_json
      }
      
      params[:sign] = sign_params2(params, prv_key)
      
      resp = RestClient.get 'https://openapi.alipay.com/gateway.do', { :params => params }
      result = JSON.parse(resp)
      puts result
      if rsa_verify_result2(result, ali_pub_key)
        if result['alipay_trade_pay_response']
          code = result['alipay_trade_pay_response']['code']
          if code && code.to_i == 10000
            return 0,result['alipay_trade_pay_response']
          else
            return code.to_i,result['alipay_trade_pay_response']['sub_msg']
          end  
        else
          return -1,'非法结果'
        end      
      else
        return 4001,'验证签名失败'
      end
    end
    
    # 交易查询
    def self.query_pay(app_id,app_auth_token,out_trade_no,prv_key,ali_pub_key)
      params = {
        app_id: app_id || SiteConfig.alipay_app_id,
        method: 'alipay.trade.query',
        charset: 'utf-8',
        sign_type: 'RSA2',
        timestamp: Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
        app_auth_token: app_auth_token,
        version: '1.0',
        biz_content: {
          out_trade_no: out_trade_no,
        }.to_json
      }
      
      params[:sign] = sign_params2(params, prv_key)
      
      resp = RestClient.get 'https://openapi.alipay.com/gateway.do', { :params => params }
      result = JSON.parse(resp)
      puts result
      key = 'alipay_trade_query_response'
      if rsa_verify_result2(result, ali_pub_key, key)
        if result[key]
          code = result[key]['code']
          if code && code.to_i == 10000
            return 0,result[key]
          else
            return code.to_i,result[key]['sub_msg']
          end  
        else
          return -1,'非法结果'
        end      
      else
        return 4001,'验证签名失败'
      end
      
    end
    
    # 撤销交易
    def self.cancel_pay(app_id,app_auth_token,out_trade_no,prv_key,ali_pub_key)
      params = {
        app_id: app_id || SiteConfig.alipay_app_id,
        method: 'alipay.trade.cancel',
        charset: 'utf-8',
        sign_type: 'RSA2',
        timestamp: Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
        app_auth_token: app_auth_token,
        version: '1.0',
        biz_content: {
          out_trade_no: out_trade_no,
        }.to_json
      }
      
      params[:sign] = sign_params2(params, prv_key)
      
      resp = RestClient.get 'https://openapi.alipay.com/gateway.do', { :params => params }
      result = JSON.parse(resp)
      puts result
      key = 'alipay_trade_cancel_response'
      if rsa_verify_result2(result, ali_pub_key, key)
        if result[key]
          code = result[key]['code']
          if code && code.to_i == 10000
            return 0,result[key]
          else
            return code.to_i,result[key]['sub_msg']
          end  
        else
          return -1,'非法结果'
        end      
      else
        return 4001,'验证签名失败'
      end
    end
    
    # 退款
    def self.refund_money()
      
    end
    
    # 提现
    def self.pay(billno, mobile, name, money)
      params = {
        app_id: SiteConfig.alipay_app_id,
        method: 'alipay.fund.trans.toaccount.transfer',
        charset: 'utf-8',
        sign_type: 'RSA2',
        timestamp: Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
        version: '1.0',
        biz_content: {
          out_biz_no: billno,
          payee_type: 'ALIPAY_LOGONID',
          payee_account: mobile,
          amount: (money / 100.0).to_s,
          payee_real_name: name || '',
          remark: '兼职工资'
        }.to_json
      }
      
      params[:sign] = sign_params(params)
      
      resp = RestClient.get 'https://openapi.alipay.com/gateway.do', { :params => params }
      result = JSON.parse(resp)
      # puts result
      if result['alipay_fund_trans_toaccount_transfer_response']
        code = result['alipay_fund_trans_toaccount_transfer_response']['code']
        if code && code.to_i == 10000
          if rsa_verify_result(result)
            return 0,'工资发放成功'
          else
            return 4001,'验证签名失败'
          end
        else
          return -2,result['alipay_fund_trans_toaccount_transfer_response']['sub_msg']
        end
      else
        return -1,'非法操作'
      end
      # {"alipay_fund_trans_toaccount_transfer_response"=>{"code"=>"10000", "msg"=>"Success", "order_id"=>"20171102110070001502230006316234", "out_biz_no"=>"201711021614212", "pay_date"=>"2017-11-02 16:14:52"}, "sign"=>"D8IkdbOCrncR3ps4UtYcBNQMx74R2M0iyDzX64L1LbkPeZR/DFxBXUHr9D9fFvLLVTEFTzpaMGF2iUxtTFLEPGZKhYb6dRPWHbFpztLdwMcuDKhuwvpSZR0YRRHIPWOhOmSII04K28TQOpdPI3rD9k5Z7GjiZNnuakKDVZUoPENPTsFdJrzRb/3rYAkX8wzaEzUKlQyUYt5sgVmZJQRCt3Xlr+UtPgAkkgwViu/+b4awQaBi1MTXmFGnKapK9y2d9q9B4BhDt+tzi9UADiUrD0VyjZ9PonO3hFYtLMG3WgkisTbbhIFYpzRvLeKLXxHYGzt3ld7TKdSARIqqWai9sw=="}
    end
    # 参数签名
    def self.sign_params(params)
      arr = params.sort
      hash = Hash[*arr.flatten]
      string = hash.delete_if { |k,v| v.blank? }.map { |k,v| "#{k}=#{v}" }.join('&')
      # string
      key = OpenSSL::PKey::RSA.new(File.read("#{Rails.root}/config/private_key.txt"))
      digest = OpenSSL::Digest::SHA256.new
      # puts string
      sign = key.sign(digest, string.force_encoding("utf-8"))
      # puts sign
      sign = Base64.encode64(sign)
      sign = sign.delete("\n").delete("\r")
      sign
    end
    
    # 验签
    def self.rsa_verify_result2(result, pub_key, field = 'alipay_trade_pay_response')
      alipay_result = result[field].to_json
      
      pub = OpenSSL::PKey::RSA.new(pub_key)
      digest = OpenSSL::Digest::SHA256.new
      
      sign = result['sign']
      # puts sign
      
      sign = Base64.decode64(sign)
      return pub.verify(digest, sign, alipay_result)
    end
    
    # 验证签名
    def self.rsa_verify_result(result)
      alipay_result = result['alipay_fund_trans_toaccount_transfer_response'].to_json
      
      pub = OpenSSL::PKey::RSA.new(File.read("#{Rails.root}/config/alipay_public_key.txt"))
      digest = OpenSSL::Digest::SHA256.new
      
      sign = result['sign']
      # puts sign
      
      sign = Base64.decode64(sign)
      return pub.verify(digest, sign, alipay_result)
    end
    
    # 签名
    def self.sign_params2(params, private_key)
      arr = params.sort
      hash = Hash[*arr.flatten]
      string = hash.delete_if { |k,v| v.blank? }.map { |k,v| "#{k}=#{v}" }.join('&')
      # string
      key = OpenSSL::PKey::RSA.new(private_key)
      digest = OpenSSL::Digest::SHA256.new
      # puts string
      sign = key.sign(digest, string.force_encoding("utf-8"))
      # puts sign
      sign = Base64.encode64(sign)
      sign = sign.delete("\n").delete("\r")
      sign
    end
    
    # 三方授权获取app_auth_token
    def self.get_app_auth_token(app_id, app_auth_code, prv_key)
      params = {
        app_id: app_id || SiteConfig.alipay_app_id,
        method: 'alipay.open.auth.token.app',
        charset: 'utf-8',
        sign_type: 'RSA2',
        timestamp: Time.zone.now.strftime('%Y-%m-%d %H:%M:%S'),
        version: '1.0',
        biz_content: {
          grant_type: 'authorization_code',
          code: app_auth_code
        }.to_json
      }
      
      params[:sign] = sign_params2(params, prv_key)
      
      resp = RestClient.get 'https://openapi.alipay.com/gateway.do', { :params => params }
      result = JSON.parse(resp)
      puts result
      if result['alipay_open_auth_token_app_response']
        code = result['alipay_open_auth_token_app_response']['code']
        if code && code.to_i == 10000
          tokens = result['alipay_open_auth_token_app_response']['tokens']
          return 0,tokens
        else
          return -2,result['alipay_open_auth_token_app_response']['sub_msg']
        end
      else
        return -1,'非法操作'
      end
    end
    
    # 通知校验
    # def self.notify_verify?(params)
    #
    #   return false if params['appid'] != SiteConfig.wx_app_id
    #   return false if params['mch_id'] != SiteConfig.wx_mch_id
    #
    #   sign = params['sign']
    #   params.delete('sign')
    #   return sign_params(params) == sign
    #
    # end
  end
end