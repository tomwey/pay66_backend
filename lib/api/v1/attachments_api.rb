module API
  module V1
    class AttachmentsAPI < Grape::API
      
      resource :assets, desc: '附件相关接口' do
        desc "单附件上传"
        params do
          optional :token, type: String, desc: '认证TOKEN'
          requires :file, type: Rack::Multipart::UploadedFile, desc: '附件文件数据'
        end
        post do
          asset = Attachment.new(data: params[:file], owner: Account.find_by(private_token: params[:token]))
          if asset.save
            status 200
            render_json(asset, API::V1::Entities::Attachment)
          else
            status 200
            render_error(5000, asset.errors.full_messages)
          end
        end # end post upload
        
        desc "多附件上传"
        params do
          optional :token, type: String, desc: '认证TOKEN'
          requires :files,   type: Array,  desc: "附件数组" do
            requires :file, type: Rack::Multipart::UploadedFile, desc: '附件文件数据'
          end
        end
        post :multi_upload do
          return render_error(5000, '至少需要1个附件') if params[:files].empty?
          
          assets = []
          params[:files].each do |param|
            asset = Attachment.create(data: param[:file], owner: Account.find_by(private_token: params[:token]))
            assets << asset if asset.present?
          end
          
          render_json(assets, API::V1::Entities::Attachment)
          
        end # end post upload
        
        desc "查询附件"
        params do
          optional :token, type: String, desc: 'TOKEN'
          requires :id, type: String, desc: '多个附件ID用英文逗号分隔'
        end
        get '/:id' do
          # user = authenticate!
          ids = params[:id].split(',')
          assets = Attachment.where(id: ids)
          render_json(assets, API::V1::Entities::Attachment)
        end # end get
        
      end # end resource
      
    end
  end
end