# == Schema Information
#
# Table name: ads
#
#  id              :integer          not null, primary key
#  title           :string
#  image           :string
#  destination_url :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  ad_unit_id      :integer
#  description     :string
#  has_description :boolean          default(FALSE)
#  default         :boolean          default(FALSE)
#  status          :integer          default(2)
#  action_text     :string
#  has_action      :boolean          default(FALSE)
#  content_type    :integer          default(0)
#  button_color    :string           default("#ffffff")
#  image_only      :boolean          default(FALSE)
#  overlap_type    :integer          default(0)
#

class Ad < ActiveRecord::Base
  attr_accessor :x, :y, :width, :height, :analytics, :has_title
  belongs_to :ad_unit
  has_one :video, dependent: :destroy
  has_one :lead_form, dependent: :destroy
  accepts_nested_attributes_for :video
  accepts_nested_attributes_for :lead_form
  has_many :leads

  TITLE_LIMITS = [55, 40, 30, 90, 80].freeze
  DESCRIPTION_LIMITS = [180, 90, 125, 5000].freeze
  ACTION_TEXT_LIMITS = [25, 10, 24].freeze

  BUTTON_COLORS = {
      default: '#ffffff',
      green: '#70ad47',
      orange: '#ed7d31',
      red: '#c00000',
      blue: '#2f5597'
  }.freeze

  CAROUSEL_TITLE_ONE_LINE_LIMIT = 35

  validates :title, presence: true, unless: :may_not_present_title?
  validates :destination_url, presence: true, if: 'lead_form.nil?'
  validate  :title_length
  validates :description, presence: true, if: :has_description
  validate  :description_length, if: :has_description
  validates :action_text, presence: true, if: :has_action
  validate  :action_text_length, if: :has_action
  validates :destination_url, length: { maximum: 2_000 },
            format: { with: URI.regexp }, if: 'destination_url.present?'
  validates_uniqueness_of :default, allow_blank: true, scope: :ad_unit_id

  scope :ordered, -> { order(created_at: :desc) }
  scope :to_publish, -> { where(status: [statuses[:published], statuses[:ready_to_publish]]) }
  scope :video_type, -> { where(content_type: [content_types[:video]]) }
  scope :image_type, -> { where(content_type: [content_types[:image]]) }

  mount_uploader :image, AdImageUploader
  after_validation :image, integrity: true, presence: true
  validates_presence_of :video, if: proc { |ad| ad.video? }

  after_save :create_image_from_video, if: proc { |ad| ad.video? }
  before_save :fetch_short_url

  enum status: [:published, :unpublished, :ready_to_publish]
  enum content_type: [:image, :video]
  enum overlap_type: [:gradient, :shade, :transparent]

  def copy
    ad = dup
    ad.status = :ready_to_publish
    ad.image = image if image.present?
    ad.video = video.copy if video.present?
    ad.lead_form = lead_form.copy if lead_form.present?
    ad
  end

  def image_url(type, size = nil)
    image_for(type, size).url
  end

  def image_for(type, size = nil)
    case type.to_s
    when 'list'
      image.send('list')
    when 'carousel'
      image_for_carousel(size)
    when 'carousel_overlay'
      image.send('size_300x250')
    when 'single_ad', 'single_ad_scroll'
      image.send("size_#{AdUnit::SINGLE_AD_IMAGE_SIZES[size]}")
    when 'lead_gen', 'lead_gen_scroll'
      image.send("size_#{AdUnit::LEAD_GEN_IMAGE_SIZES[size]}")
    end
  end

  def image_for_carousel(size)
    if ad_unit.amp? && size.nil?
      [image.send('size_300x150'), image.send('carousel')]
    elsif ad_unit.amp? && size == '300x250'
      image.send('size_300x150')
    elsif ad_unit.amp? && size == '970x260'
      image.send('carousel')
    else
      image.send('carousel')
    end
  end

  def should_have_action?
    ad_unit.single_ad? || ad_unit.single_ad_scroll?
  end

  def should_have_description?
    ad_unit.single_ad? || ad_unit.lead_gen? || ad_unit.single_ad_scroll? || ad_unit.lead_gen_scroll?
  end

  def update_content_type
    should_update_to_video = ad_unit.can_has_video? && video.present?
    self.content_type = should_update_to_video ? Ad.content_types[:video] : Ad.content_types[:image]
  end

  def update_video_type
    video_infini_condition = video_infini?
    not_single_infini_condition = !ad_unit.single_ad? && video_infini_condition
    infini_not_300x250_condition = video_infini_condition && ad_unit.content_sizes.exclude?('300x250')
    if not_single_infini_condition || infini_not_300x250_condition
      self.status = Ad.statuses[:unpublished]
      self.save
    end
  end

  def edit_for_list
    if has_description
      self.title = title[0..TITLE_LIMITS[2] - 1]
      self.description = description[0..DESCRIPTION_LIMITS[1] - 1]
      self.has_action = false
    end
    self.has_description = false if has_action
    self.action_text = action_text[0..ACTION_TEXT_LIMITS[0] - 1] if has_action
  end

  def edit_for_carousel
    if has_description
      self.title = title[0..TITLE_LIMITS[0] - 1]
      if has_action
        self.description = description[0..DESCRIPTION_LIMITS[1] - 1]
      else
        self.description = description[0..DESCRIPTION_LIMITS[2] - 1]
      end
    end

    self.action_text = action_text[0..ACTION_TEXT_LIMITS[0] - 1] if has_action
  end

  def edit_for_carousel_overlay
    if has_description
      self.title = title[0..TITLE_LIMITS[2] - 1]
      self.description = description[0..DESCRIPTION_LIMITS[1] - 1]
    end
  end

  def edit_for_single_ad
    if has_action
      self.action_text = action_text[0..ACTION_TEXT_LIMITS[2] - 1]
    else
      self.action_text = 'Click here'
      self.has_action = true
    end
    self.has_description = true unless has_description
  end

  def edit_for_lead_gen
    if has_action
      self.action_text = action_text[0..ACTION_TEXT_LIMITS[0] - 1]
    end
    self.has_description = true unless has_description
  end

  def edit_for_lead_gen_scroll
    if has_action
      self.action_text = action_text[0..ACTION_TEXT_LIMITS[0] - 1]
    end
    self.has_description = true unless has_description
  end

  def edit_for_single_ad_scroll
    if has_action
      self.action_text = action_text[0..ACTION_TEXT_LIMITS[2] - 1]
    else
      self.action_text = 'Click here'
      self.has_action = true
    end
    self.has_description = true unless has_description
  end

  def video_infini?
    video.present? && video.infini?
  end

  def may_not_present_title?
    image_only || video_infini? || ad_unit.carousel_overlay?
  end

  def has_title
    title.present?
  end

  private

  def title_length
    return if title.blank?

    limit_index =
      case ad_unit.content_type
      when 'list'
        has_description.present? ? 2 : 0
      when 'carousel'
        has_description.present? ? 0 : 3
      when 'carousel_overlay'
        has_description.present? ? 1 : 0
      when 'single_ad', 'single_ad_scroll'
        4
      when 'lead_gen', 'lead_gen_scroll'
        1
      end
    max_length = TITLE_LIMITS[limit_index]
    errors.add(:title, :too_long, count: max_length) if title.length > max_length
  end

  def description_length
    return if description.blank?

    limit_index =
      case ad_unit.content_type
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
    max_length = DESCRIPTION_LIMITS[limit_index]
    errors.add(:description, :too_long, count: max_length) if description.length > max_length
  end

  def action_text_length
    return if action_text.blank?

    limit_index =
      case ad_unit.content_type
      when 'list'
        0
      when 'carousel'
        0
      when 'carousel_overlay'
        0
      when 'single_ad', 'single_ad_scroll'
        0
      when 'lead_gen', 'lead_gen_scroll'
        0
      end

    max_length = ACTION_TEXT_LIMITS[limit_index]
    errors.add(:action_text, :too_long, count: max_length) if action_text.length > max_length
  end

  def create_image_from_video
    Ad.skip_callback :save, :after, :create_image_from_video
    begin
      if video.youtube?
        uid = video.link.match(Video::YT_LINK_FORMAT)[2]
        self.remote_image_url = "https://img.youtube.com/vi/#{uid}/mqdefault.jpg"
      elsif video.video.thumb.file.present?
        image_src = video.video.thumb.file.file
        src_file = File.new(image_src)
        self.image = src_file
      end
      save
    rescue
    end
  ensure
    Ad.set_callback :save, :after, :create_image_from_video, if: proc { |ad| ad.video? }
  end

  def fetch_short_url
    google_api_key = Rails.application.secrets.google_api_key
    uri = URI.parse("https://www.googleapis.com/urlshortener/v1/url?key=#{google_api_key}")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = JSON.dump({"longUrl" => destination_url})
    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    if response.code == '200'
      short_url = JSON.parse(response.body)["id"]
      self.short_url = short_url
    else
      self.short_url = destination_url
    end
  end
end
