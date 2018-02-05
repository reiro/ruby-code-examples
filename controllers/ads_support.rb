module AdsSupport
  extend ActiveSupport::Concern

  included do
    before_action :fetch_campaign, except: [:fetch_images, :fetch_title, :fetch_video]
    before_action :fetch_ad_unit, except: [:fetch_images, :fetch_title, :fetch_video]
    before_action :fetch_ad, only: [:edit, :update, :destroy]
    after_action :encode_video, only: [:create, :update]
    after_action :generate_ad_unit_screenshot, only: [:create, :update, :destroy]
  end

  def new
    @ad = @ad_unit.ads.build
    @video = @ad.build_video if @ad_unit.can_has_video?
    if @ad_unit.lead_gen_type?
      @lead_form = @ad.build_lead_form
      @lead_form.build_field
    end
  end

  def edit
    @lead_form = @ad.lead_form
  end

  def create
    @ad = @ad_unit.ads.build(ad_params)
    @ad.description = nil unless @ad.has_description
    @ad.action_text = nil unless @ad.has_action
    @ad.save
    @ad_unit.update(sequence_ids: @ad_unit.sequence_ids << @ad.id)
  end

  def update
    if ad_params[:default] == '1' && @ad.default.blank?
      @ad_unit.ads.update_all(default: false)
    end

    @ad.assign_attributes(ad_params)
    @ad.description = nil unless @ad.has_description
    @ad.action_text = nil unless @ad.has_action
    @ad.status = :ready_to_publish unless @ad.unpublished?
    @ad.save
  end

  def destroy
    @ad_unit.update(sequence_ids: @ad_unit.sequence_ids - [@ad.id.to_s])
    @ad.destroy
  end

  def fetch_images
    destination_url = params[:destination_url]
    @ad_id = params[:ad_id]
    @content_type = params[:content_type]

    image_spider = ImageSpider.new(destination_url)

    if @ad_id && image_spider.url_valid?
      @fetched_images_srcs = image_spider.fetch_images
      render layout: false
    else
      head :bad_request
    end
  end

  def fetch_video
    link = params[:video_url]
    uid = link.match(Video::YT_LINK_FORMAT)
    @video_uid = uid[2]
    render layout: false
  end

  def fetch_title
    destination_url = params[:destination_url]
    @ad_id = params[:ad_id]

    image_spider = ImageSpider.new(destination_url)

    title = image_spider.fetch_title
    description = image_spider.fetch_description
    if description.present?
      limit_index =
          case params[:ad_unit_content_type]
          when 'list', 'carousel_overlay'
            1
          when 'carousel'
            has_action.present? ? 0 : 2
          when 'single_ad'
            2
          when 'lead_gen'
            0
          when 'lead_gen_scroll', 'single_ad_scroll'
            3
          end
      description = description.truncate(Ad::DESCRIPTION_LIMITS[limit_index], separator: ' ')
    end
    if @ad_id && image_spider.url_valid?
      render json: { title: title, description: description }
    else
      head :bad_request
    end
  end

  def download_leads
    @ad = Ad.find(params[:ad_id])
    @leads = @ad.leads.ordered

    respond_to do |format|
      format.csv { send_data @leads.to_csv(@ad), filename: "leads-#{Date.today}.csv" }
      format.xlsx
    end
  end

  private

  def generate_ad_unit_screenshot
    AdUnitScreenshotsJob.perform_later(@ad_unit, @ad_unit.encoded_id, request.base_url)
  end

  def convert_data_uri_to_upload
    image_data = split_base64(@ad_params[:image])
    image_data_string = image_data[:data]
    image_data_binary = Base64.decode64(image_data_string)

    temp_img_file = Tempfile.new('infini_image')
    temp_img_file.binmode
    temp_img_file << image_data_binary
    temp_img_file.rewind

    img_params = {:filename => 'infini_image', :type => image_data[:type], :tempfile => temp_img_file}
    uploaded_file = ActionDispatch::Http::UploadedFile.new(img_params)
    uploaded_file.original_filename << '.jpg'

    @ad_params[:image] = uploaded_file
  end

  def split_base64(uri_str)
    if match = uri_str.match(/^data:(.*?);(.*?),(.*)$/)
      uri = Hash.new
      uri[:type] = match[1] # "image/gif"
      uri[:encoder] = match[2] # "base64"
      uri[:data] = match[3] # data string
      uri[:extension] = match[1].split('/')[1] # "gif"
      return uri
    else
      return nil
    end
  end

  def fetch_ad
    @ad = @ad_unit.ads.find(params[:id])
  end

  def fetch_ad_unit
    @ad_unit = @campaign.ad_units.find(params[:ad_unit_id])
  end

  def fetch_campaign
    @campaign = campaigns.find(params[:campaign_id])
  end

  def encode_video
    if @ad.valid? && @ad.video? && @ad.video.file?
      VideoEncodingJob.perform_later(@ad.video)
    end
  end

  def prepare_params
    %i(x y width height).each { |coord| @ad_params[coord] = @ad_params[coord]&.split(',') }
    if @ad_unit.single_ad_type?
      @ad_params[:has_action] = true
      @ad_params[:has_description] = true
      convert_data_uri_to_upload if @ad_params[:image].try(:match, /^data:(.*?);(.*?),(.*)$/)
      @ad_params[:title] = 'new ad' unless @ad_params[:title]
    end
    if @ad_unit.can_has_video?
      should_delete_video_attributes =
          (@ad_params[:content_type] == 'image') ||
          (@ad_params[:video_attributes][:video_type] == 'file' &&
           @ad_params[:video_attributes][:video].nil? && @ad.video.present?)
      @ad_params.delete(:video_attributes) if should_delete_video_attributes
    end
    if @ad_unit.lead_gen_type?
      @ad_params[:has_description] = true
      custom_fields_params = params['ad']['lead_form_attributes']['custom_fields']
      custom_fields_params =
        if custom_fields_params.present?
          custom_fields_params.is_a?(Hash) ? custom_fields_params.values : custom_fields_params
        else
          []
        end
      custom_fields_params.each { |f| f['name'] = f['label'].parameterize.underscore }
      @ad_params[:lead_form_attributes][:custom_fields] = custom_fields_params
      @ad_params[:lead_form_attributes][:fields] = params['ad']['lead_form_attributes']['fields'].map(&:last)
    end
    if @ad_unit.carousel_overlay?
      @ad_params[:title] = '' if @ad_params[:title].nil?
    end

    @ad_params
  end

  def ad_params
    if @ad_params.present?
      @ad_params
    else
      @ad_params = params.require(:ad).permit(
        :x,
        :y,
        :width,
        :height,
        :title,
        :has_title,
        :image,
        :remote_image_url,
        :image_cache,
        :destination_url,
        :description,
        :has_description,
        :default,
        :status,
        :action_text,
        :has_action,
        :button_color,
        :content_type,
        :image_only,
        :overlap_type,
        :impression_tracker,
        :include_like_share,
        video_attributes: [:link, :infini_link, :youku_link, :video, :video_type, :autoplay],
        lead_form_attributes: [:id, :fields, :custom_fields, :privacy_link,
                               :message, :description, :form_title, :zapier,
                               :adzymic, :zapier_webhook, :zapier_confirmed]
      )
      prepare_params
    end
  end
end
