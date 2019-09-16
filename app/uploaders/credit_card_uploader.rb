# encoding: utf-8

class CreditCardUploader < BaseUploader

  storage :qiniu
  
  version :large do
    process resize_to_fill: [287, 175]
  end
  
  # version :cover do
  #   process resize_to_fill: [354, 150]
  # end
  
  version :thumb do
    process resize_to_fill: [120, 78]
  end
  
  version :small, from_version: :thumb do
    process resize_to_fill: [60, 39]
  end

  def filename
    if super.present?
      "#{secure_token}.#{file.extension}"
    end
  end
  
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
  
  def extension_white_list
    %w(jpg jpeg png webp)
  end
  
  protected
    def secure_token
      var = :"@#{mounted_as}_secure_token"
      model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
    end

end
