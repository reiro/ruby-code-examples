class AdImageUploader < BaseUploader
  INDEX_BY_SIZE = { '300x250': 0, '300x150': 1, '300x90': 2, '250x90': 3 }.freeze

  process :quality => 90

  version :cropped do
    process :crop, if: :crop_needed?
    process resize_to_limit: [800, 800]
  end

  version :list, from_version: :cropped do
    process resize_to_fill_gif: [60, 60]
  end

  version :carousel, from_version: :cropped do
    process resize_to_fill_gif: [260, 130]
  end

  version :size_300x250 do
    process crop: INDEX_BY_SIZE[:'300x250'], if: :crop_needed?
    process resize_to_fill_gif: [298, 248]
  end

  version :size_300x150 do
    process crop: INDEX_BY_SIZE[:'300x150'], if: :crop_needed?
    process resize_to_fill_gif: [298, 148]
  end

  version :size_300x90 do
    process crop: INDEX_BY_SIZE[:'300x90'], if: :crop_needed?
    process resize_to_fill_gif: [298, 88]
  end

  version :size_250x90 do
    process crop: INDEX_BY_SIZE[:'250x90'], if: :crop_needed?
    process resize_to_fill_gif: [248, 88]
  end

  def crop_needed?(_image)
    model.x.present? && model.y.present? && model.width.present? && model.height.present?
  end

  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  def crop(index = 0)
    x = model.x[index].to_i
    y = model.y[index].to_i
    w = model.width[index].to_i
    h = model.height[index].to_i

    manipulate! do |img|
      if img[:format].downcase == 'gif'
        img.repage("0x0")
        img.coalesce
        img.crop("#{w}x#{h}+#{x}+#{y}")
        img << "+repage"
      else
        img.crop("#{w}x#{h}+#{x}+#{y}")
      end
      img
    end
  end

  def resize_to_fill_gif(width, height)
    if self.file.content_type.include?('gif')
      manipulate! do |img|
        img_path = img.path
        system("gifsicle #{img_path} --resize #{width}x#{height} > /tmp/temp.gif")
        system("mv /tmp/temp.gif #{img_path}")
        img
      end
    else
      resize_to_fill(width, height)
    end
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
