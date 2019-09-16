require 'rest-client'
module API
  module V1
    class AdminAPI < Grape::API
      helpers API::SharedParams
      
      namespace "admin" do
        resource :u, desc: '账号相关的接口' do
          desc "账号登录"
          params do
            requires :mobile, type: String, desc: "登录手机"
            requires :password, type: String, desc: "密码"
            requires :cid, type: String, desc: "机构ID"
          end
          post :login do
            mobile = params[:mobile]
            password = params[:password]
          
            merch = Company.find_by(id: params[:cid])
            if merch.blank? or merch.deleted_at.present?
              return render_error(4004, "机构不存在")
            end
          
            account = Account.where(mobile: mobile, company_id: merch.id).first
            if account.blank?
              return render_error(4004, "账号不存在，请联系管理员创建")
            end
          
            if !account.authenticate(password)
              return render_error(1002, "密码不正确")
            end
          
            if !account.opened
              return render_error(1003, "账号被禁用")
            end
          
            account.last_login_at = Time.zone.now
            account.last_login_ip = client_ip
            account.login_count  += 1
            account.save!(validate: false)
          
            render_json(account, API::V1::Entities::SimpleAccount)
          end # end login
          
          desc "获取首页数据"
          params do
            requires :token, type: String, desc: "登录TOKEN"
          end
          get :home do
            account = authenticate_account!
            render_json(account, API::V1::Entities::Account)
          end # end get home
        end # end resource
        
        # 通用接口
        resource :common, desc: '通用相关接口' do
          desc "通用查询接口"
          params do
            requires :token, type: String, desc: '认证TOKEN'
            requires :class, type: String, desc: "需要操作资源类名"
            optional :conds, type: Array[JSON], desc: "查询条件"
            optional :sorts, type: Array[JSON], desc: "排序"
            use :pagination
          end
          get '/:class/list' do
            account = authenticate_account!
            
            begin
              klass = params[:class].classify.constantize
            rescue => ex
              return render_error(5000, '不存在的资源')
            end
            
            if klass.new.has_attribute?(:deleted_at)
              if klass.to_s == 'Company'
                data = klass.where(pid: account.company_id, deleted_at: nil)
              else
                data = klass.where(company_id: account.company_id, deleted_at: nil)
              end
            else
              # data = klass.where(company_id: account.company_id)
              if klass.to_s == 'Company'
                data = klass.where(pid: account.company_id)
              else
                data = klass.where(company_id: account.company_id)
              end
            end
            
            if params[:conds]
              params[:conds].each do |json|
                key = json['k']
                op  = json['op'] || '='
                next if key.blank? or op.blank?
                
                next unless (klass.respond_to?(key.to_sym) or klass.new.respond_to?(key.to_sym) or op == 'kw')
                
                next unless ['kw', 'lk', 'rg', '>', '<', '=', '>=', '<=', 'not', '='].include? op.downcase
                
                op = op.downcase
                
                case op
                when 'kw'
                  keys = key.split(',')
                  temp = []
                  keys.each do |k|
                    temp << "#{k} like :keyword"
                  end
                  data = data.where(temp.join(" or "), keyword: "%#{json['v']}%")
                when 'lk'
                  data = data.where("#{key} like ?", "%#{json['v']}%")
                when 'rg'
                  if json['v'].present?
                    first,last = json['v'].split(',')
                    data = data.where("#{key} between ? and ?", first, last)
                  end
                when 'not'
                  data = data.where.not(key.to_sym => json['v'].blank? ? nil : json['v'])
                when '='
                  if key.include? '__assoc' # 关联查询
                    data = data.send key.to_sym, json['v']
                  else
                    data = data.where(key.to_sym => json['v'].blank? ? nil : json['v'])
                  end
                else
                  data = data.where("#{key} #{op} ?", json['v'])
                end
              end
            end
            
            # 排序
            # puts params[:sorts]
            if params[:sorts]
              temp = []
              params[:sorts].each do |json|
                # json.each do |k,v|
                  temp << "#{json['k']} #{json['v']}"
                # end
              end
              # puts temp
              if temp.any?
                data = data.order(temp.join(','))
              end
            end
            
            if params[:page]
              data = data.paginate page: params[:page], per_page: page_size
              total = data.total_entries
            else
              total = data.size
            end
            
            render_json(data, "API::V1::Entities::#{klass}".constantize, {}, total)
            
          end # end get
          
          desc "通用保存接口"
          params do
            requires :token,   type: String, desc: '认证TOKEN'
            requires :class,   type: String, desc: "需要操作资源类名"
            optional :id,      type: String, desc: "资源ID"
            optional :payload, type: JSON,   desc: "资源JSON数据"
            # optional :files,   type: Array,  desc: "附件数组" do
            #   requires :file, type: Rack::Multipart::UploadedFile, desc: '附件文件数据'
            # end
          end
          post '/:class/save' do
            account = authenticate_account!
            
            begin
              klass = params[:class].classify.constantize
            rescue => ex
              return render_error(5000, '不存在的资源')
            end
            obj = klass.find_by(id: params[:id])
            if obj.blank?
              obj = klass.new
              if klass.to_s == 'Company'
                obj.pid = account.company_id
              else
                obj.company_id = account.company_id
              end
              if obj.respond_to? :uploader
                obj.uploader = account
              elsif obj.class.to_s != 'Timetable' and obj.respond_to? :owner
                obj.owner = account
              elsif obj.respond_to? :creator
                obj.creator = account
              end
            end
            
            if params[:payload]
              params[:payload].each do |k,v|
                # puts k
                if obj.respond_to?("#{k}=") and obj.permit_params.include?(k)
                  # puts v
                  obj.send "#{k}=", v
                end
              end
            end
            
            is_add = obj.new_record?
            
            if obj.save
              title = "#{is_add ? '新建' : '更新'}#{obj.model_name.human}"
              action = is_add ? 'create' : 'update'
              SysOperLog.create(owner: account, 
                                title: title, 
                                resource_name: obj.class, 
                                action: action,
                                resource_ids: obj.id,
                                ip: client_ip,
                                company_id: account.company_id,
                                api_uri: "/common/#{params[:class]}/save"
                                )
              render_json(obj, "API::V1::Entities::#{klass}".constantize)
            else
              render_error(2000, obj.errors.full_messages)
            end
          end # end post
          
          desc "通用启用、禁用接口"
          params do
            requires :token, type: String,  desc: "认证TOKEN"
            requires :class, type: String,  desc: "需要操作的资源类名"
            requires :ids,   type: String,  desc: "资源ID，多个ID用英文逗号分隔"
            requires :state, type: Integer, desc: "值为0或1，0表示打开，1表示关闭"
          end
          post '/:class/open_or_close' do
            account = authenticate_account!
            
            begin
              klass = params[:class].classify.constantize
            rescue => ex
              return render_error(5000, '不存在的资源')
            end
            
            unless klass.new.has_attribute?(:opened)
              return render_error(-2, '不支持此操作')
            end
            
            unless [0,1].include? params[:state]
              return render_error(-1, '不正确的state参数')
            end
            
            ids = params[:ids].split(',')
            ids = klass.where(id: ids).pluck(:id)
            if ids.empty?
              return render_error(4004, '没有找到资源')
            end
            klass.where(id: ids).update_all(opened: (params[:state] == 0 ? false : true))
            
            SysOperLog.create(owner: account, 
                              title: "#{params[:state] == 1 ? '打开' : '关闭'}#{klass.model_name.human}", 
                              resource_name: klass, 
                              action: "#{params[:state] == 1 ? 'open' : 'close'}",
                              resource_ids: ids.join(','),
                              ip: client_ip,
                              company_id: account.company_id,
                              api_uri: "/common/#{params[:class]}/open_or_close"
                              )
            
            render_json_no_data
          end # end 
          
          desc "通用审核认证"
          params do
            requires :token, type: String,  desc: "认证TOKEN"
            requires :class, type: String,  desc: "需要操作的资源类名"
            requires :ids,   type: String,  desc: "资源ID，多个ID用英文逗号分隔"
          end
          post '/:class/approve' do
            account = authenticate_account!
            
            begin
              klass = params[:class].classify.constantize
            rescue => ex
              return render_error(5000, '不存在的资源')
            end
            
            ids = params[:ids].split(',')
            ids = klass.where(id: ids, deleted_at: nil).pluck(:id)
            if ids.empty?
              return render_error(4004, '没有找到资源')
            end
            
            # 记录日志
            SysOperLog.create(owner: account, 
                              title: "#{klass.model_name.human}认证通过", 
                              resource_name: klass, 
                              action: "approve",
                              resource_ids: ids.join(','),
                              ip: client_ip,
                              company_id: account.company_id,
                              api_uri: "/common/#{params[:class]}/approve"
                              )
                              
            klass.where(id: ids).update_all(approved_at: Time.zone.now)
            
            render_json_no_data
          end # end 
          
          desc "通用删除"
          params do
            requires :token, type: String,  desc: "认证TOKEN"
            requires :class, type: String,  desc: "需要操作的资源类名"
            requires :ids,   type: String,  desc: "资源ID，多个ID用英文逗号分隔"
          end
          post '/:class/delete' do
            account = authenticate_account!
            
            begin
              klass = params[:class].classify.constantize
            rescue => ex
              return render_error(5000, '不存在的资源')
            end
            
            ids = params[:ids].split(',')
            ids = klass.where(id: ids).pluck(:id)
            if ids.empty?
              return render_error(4004, '没有找到资源')
            end
            
            # 记录日志
            SysOperLog.create(owner: account, 
                              title: "删除#{klass.model_name.human}", 
                              resource_name: klass, 
                              action: "delete",
                              resource_ids: ids.join(','),
                              ip: client_ip,
                              company_id: account.company_id,
                              api_uri: "/common/#{params[:class]}/delete"
                              )
                              
            if klass.new.has_attribute?(:deleted_at)
              # 假删除
              klass.where(id: ids).update_all(deleted_at: Time.zone.now)
            else
              # 真删除
              klass.where(id: ids).delete_all
            end
            
            render_json_no_data
          end # end 
          
          desc "通用数据导入"
          params do
            requires :token, type: String,  desc: "认证TOKEN"
            requires :class, type: String,  desc: "需要操作的资源类名"
            requires :payload, type: JSON,   desc: "资源JSON数据"
          end
          post '/:class/import' do
            account = authenticate_account!
            
            begin
              klass = params[:class].classify.constantize
            rescue => ex
              return render_error(5000, '不存在的资源')
            end
            
            ids = nil
            if klass.respond_to? :import
              ids = klass.import(params[:payload], account.company_id)
            end
            
            # 记录日志
            SysOperLog.create(owner: account, 
                              title: "#{klass.model_name.human}数据导入", 
                              resource_name: klass, 
                              action: "import",
                              resource_ids: ids.join(','),
                              ip: client_ip,
                              company_id: account.company_id,
                              api_uri: "/common/#{params[:class]}/import"
                              )
            if ids.blank? or ids.empty?
              render_error(5000, '未有导入成功的数据!')
            else
              { code: 0, message: "成功导入#{ids.size}条数据" }
            end
            
          end # end post 
          
        end # end resource
        
        # 学生绑定家长
        resource :students, desc: '学生相关的接口' do
          desc "学生绑定家长"
          params do
            requires :token, type: String, desc: '认证TOKEN'
            requires :pids,  type: Array, desc: '待绑定的家长ID'
          end
          post '/:id/bind_parents' do
            account = authenticate_account!
            
            stu = Student.find_by(id: params[:id])
            if stu.blank? or stu.deleted_at.present?
              return render_error(4004, '学生不存在')
            end
            
            ids = Parent.where(id: params[:pids], deleted_at: nil).pluck(:id)
            if ids.empty?
              return render_error(4004, '家长不存在')
            end
            
            spids = []
            ids.each do |pid|
              sp = StudentParent.create(student_id: stu.id, parent_id: pid, company_id: account.company_id, binded_at: Time.zone.now)
              if sp
                spids << sp.id
              end
            end
            
            if spids.size == 0
              return render_error(5000, '全部绑定失败')
            end
            
            # 记录日志
            SysOperLog.create(owner: account, 
                              title: "绑定家长", 
                              resource_name: 'StudentParent', 
                              action: "create",
                              resource_ids: spids.join(','),
                              ip: client_ip,
                              company_id: account.company_id,
                              api_uri: "/students/#{params[:id]}/bind_parents"
                              )
            render_json_no_data
            
          end # end post bind parents
        end # end resource
        
        # 批量创建课程表
        resource :class_schedules, desc: "课程表相关接口" do
          desc "创建课程表"
          params do
            requires :token, type: String, desc: "认证TOKEN"
            requires :dates, type: String, desc: "课表日期，多个日期用英文逗号分隔" 
            requires :payload, type: JSON, desc: "除开上课日期外的一条上课安排数据"
          end
          post do
            account = authenticate_account!
            
            dates = params[:dates].split(',')
            return render_error(-1, '至少需要一个课表日期') if dates.empty?
            
            ids = []
            dates.each do |date|
              obj = ClassSchedule.new
              obj.company_id = account.company_id
              obj.plan_date = date
              
              if params[:payload]
                params[:payload].each do |k,v|
                  # puts k
                  if obj.respond_to?("#{k}=") and obj.permit_params.include?(k)
                    # puts v
                    obj.send "#{k}=", v
                  end
                end
              end
              
              if obj.save
                ids << obj.id
              end
              
            end
            
            # 记录日志
            SysOperLog.create(owner: account, 
                              title: "创建课表计划", 
                              resource_name: 'ClassSchedule', 
                              action: "create",
                              resource_ids: ids.join(','),
                              ip: client_ip,
                              company_id: account.company_id,
                              api_uri: "/admin/class_schedules"
                              )
            if ids.blank? or ids.empty?
              render_error(5000, '没有创建成功')
            else
              { code: 0, message: "成功创建#{ids.size}条" }
            end
            
          end # end post
        end # end resource
        
      end # end ns
    end
  end
end