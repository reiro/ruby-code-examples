class DoubleclickTag
  MACROS = {
    dcm: { click: '%c', cache_buster: '%n' },
    dbm: { click: '${CLICK_URL}', cache_buster: '${CACHEBUSTER}' },
    dfp: { click: '%%CLICK_URL_UNESC%%', cache_buster: '%%CACHEBUSTER%%', site: '%%SITE%%' },
    gdn: { click: '%%CLICK_URL_UNESC%%', cache_buster: '%%CACHEBUSTER%%' },
    sizmek: { click: '[%MMclicktrackingURL%]', cache_buster: '[%Random%]' },
    aol: { click: '_ADCLICKDEC_', cache_buster: '_ADTIME_' },
    app_nexus: { click:  '${CLICK_URL}', cache_buster: '${CACHEBUSTER}' }
  }
  AD_SERVERS = {
    dcm: :doubleclick,
    dbm: :doubleclick,
    dfp: :doubleclick,
    gdn: :doubleclick,
    sizmek: :sizmek,
    aol: :aol,
    app_nexus: :nexus
  }
  attr_reader :zip_data

  def self.networks
    MACROS.keys
  end

  def self.amp_networks
    MACROS.keys - [:sizmek]
  end

  def initialize(ad_unit, network)
    @ad_unit = ad_unit
    @macros = MACROS[network]
    @ad_server = AD_SERVERS[network]
    @tempfiles = Set.new
    @files = []
    @coder = Hashids.new(Rails.application.secrets.hash_ids_salt, 16)
  end

  def archive_filename
    "Ad_unit_#{@ad_unit.id}.zip"
  end

  def publish_tag_files
    upload_creatives
    if @ad_unit.published_at.present?
      CdnInvalidationJob.perform_later(@ad_unit.id)
    else
      @ad_unit.update(published_at: DateTime.current)
    end
    update_stats_engine

    template_name = @ad_server == :sizmek ? 'sizmek_js_tag.slim' : 'doubleclick_js_tag.slim'
    template_filename = Rails.root.join('lib', 'doubleclick', 'views', template_name)

    @ad_unit.sizes.map do |size|
      tag = generate_js_tag_data(size)
      Slim::Template.new(template_filename).render(tag)
    end
  end

  private

  def zipfile
    @zip ||= Tempfile.new(archive_filename)
    @tempfiles << @zip

    @zip
  end

  def static_assets_path
    Rails.root.join('lib', 'doubleclick', 'images')
  end

  def storage_directory
    @directory ||= StorageMule.get_directory
  end

  def video_storage_directory
    @video_directory ||= StorageMule.get_video_directory
  end

  def encode_filename(filename)
    Digest::MD5.hexdigest(filename)
  end

  def generate_js_tag_data(size)
    tag = OpenStruct.new
    numbers = [@ad_unit.id, @ad_unit[:content_type], size.to_i]
    tag.ad_unit_link = "//engine.enzymic.co/ad_units/#{@coder.encode(numbers)}"
    tag.content_size = @ad_unit.content_size(size)
    tag.ad_unit_size = ad_unit_size(tag.content_size)
    tag.ad_unit = @ad_unit
    tag.ad_server = @ad_server
    tag.macros = @macros
    tag
  end

  def encode_ad_filename(*ids)
    @coder.encode(ids)
  end

  def upload_creatives
    upload_images
    upload_videos
  end

  def upload_images
    images = ads_images(@ad_unit.ads.to_publish).flatten.uniq
    images << @ad_unit.sponsored_logo if @ad_unit.updated_at.to_i > @ad_unit.published_at.to_i
    upload_resources(images, storage_directory)
  end

  def upload_videos
    return unless @ad_unit.can_has_video?
    resources = @ad_unit.ads.video_type.to_publish.each_with_object([]) do |ad, videos|
      next if ad.video.youtube? || ad.video.infini? || ad.video.youku? || ad.video.updated_at.to_i <= @ad_unit.published_at.to_i
      videos << ad.video.video
    end
    upload_resources(resources, video_storage_directory)
  end

  def upload_resources(resources, storage)
    resources.each do |resource|
      storage.files.create(
        key: encode_filename(resource.file.filename),
        body: File.open(resource.path),
        public: true
      )
    end
  end

  def ads_images(ads)
    if @ad_unit.single_ad_type? || @ad_unit.lead_gen_type?
      ads.inject([]) do |images, ad|
        return images if ad.video&.infini? || ad.video&.youku?
        if ad.updated_at.to_i > @ad_unit.published_at.to_i
          images + @ad_unit.content_sizes.map { |size| ad.image_for(@ad_unit.content_type, size) }
        else
          images
        end
      end
    else
      ads.each_with_object([]) do |ad, images|
        images << ad.image_for(@ad_unit.content_type) if ad.updated_at.to_i > @ad_unit.published_at.to_i
      end
    end
  end

  def ad_unit_size(content_size)
    values = content_size.split('x')
    {
      width: values.first,
      height: values.last
    }
  end

  def update_stats_engine
    Analytics::Client.new.post_ad_unit(@ad_unit)
  end
end
