# == Schema Information
#
# Table name: ad_units
#
#  id                :integer          not null, primary key
#  name              :string
#  content_type      :integer
#  auto_optimization :boolean          default(FALSE)
#  sizes             :text             is an Array
#  sponsored_logo    :string
#  sponsored_label   :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  campaign_id       :integer
#  published_at      :datetime
#  sequence          :boolean          default(FALSE)
#  sequence_ids      :text             default([]), is an Array
#

class AdUnit < ActiveRecord::Base
  attr_accessor :analytics

  CONTENT_SIZES = {
    '0': '300x250',
    '1': '300x600',
  }.with_indifferent_access.freeze

  LIST_CONTENT_SIZES = CONTENT_SIZES.merge({
    '2': '970x90',
    '3': '728x90',
    '4': '320x480',
    '5': '320x50',
    '6': '300x50'
  }.freeze).with_indifferent_access.freeze

  SINGLE_AD_CONTENT_SIZES = CONTENT_SIZES.merge({
    '2': '970x90',
    '3': '728x90',
    '4': '970x250',
    '5': '320x480'
  }.freeze).with_indifferent_access.freeze

  CAROUSEL_CONTENT_SIZES = CONTENT_SIZES.merge({
    '2': '970x250',
    '3': '320x480'
  }.freeze).with_indifferent_access.freeze

  CAROUSEL_OVERLAY_CONTENT_SIZES = CONTENT_SIZES.merge({
    '2': '970x250',
    '3': '320x480'
  }.freeze).with_indifferent_access.freeze

  LEAD_GEN_CONTENT_SIZES = CONTENT_SIZES.merge({
      '2': '320x480'
  }.freeze).with_indifferent_access.freeze

  LEAD_GEN_SCROLL_CONTENT_SIZES = CONTENT_SIZES.merge({
      '2': '320x480'
  }.freeze).with_indifferent_access.freeze

  SINGLE_AD_SCROLL_CONTENT_SIZES = CONTENT_SIZES.merge({
      '2': '320x480'
  }.freeze).with_indifferent_access.freeze

  ADS_MINIMUM_COUNT = [
    [3, 6, 3, 2, 5, 1, 1],
    [1, 3, 4, 4],
    [1, 3, 4, 4],
    [1, 1, 1, 1, 1, 1],
    [1, 1, 1],
    [1, 1, 1],
    [1, 1, 1]
  ].freeze

  CAROUSEL_LOADED_ADS_COUNT = [3, 5, 5, 4].freeze
  CAROUSEL_SHOWED_ADS_COUNT = [2, 3, 4, 2].freeze
  VERTICAL_CAROUSEL_SIZES = %w(300x600 320x480).freeze

  SINGLE_AD_IMAGE_SIZES = {
    '300x250' => '300x150',
    '300x600' => '300x250',
    '970x250' => '300x250',
    '728x90' => '250x90',
    '970x90' => '300x90',
    '320x480' => '300x150'
  }.freeze

  SINGLE_AD_SCROLL_IMAGE_SIZES = {
      '300x250' => '300x150',
      '300x600' => '300x250',
      '320x480' => '300x150'
  }.freeze

  DEFAULT_DATA = {
      "clicks" => 0,
      "swipes" => 0,
      "5s_views" => 0,
      "50%_views" => 0,
      "100%_views" => 0,
      "impressions" => 0,
      "submits" => 0,
      "likes" => 0,
      "tw_shares" => 0,
      "fb_shares" => 0,
      "in_shares" => 0,
      "wa_shares" => 0,
      "email_shares" => 0
  }.freeze

  LEAD_GEN_IMAGE_SIZES = {
      '300x250' => '300x150',
      '300x600' => '300x150',
      '320x480' => '300x150'
  }.freeze

  LEAD_GEN_SCROLL_IMAGE_SIZES = {
      '300x250' => '300x150',
      '300x600' => '300x150',
      '320x480' => '300x150'
  }.freeze

  before_validation :sizes_sanitization
  before_save :set_defaults
  after_update :edit_ads

  mount_uploader :sponsored_logo, SponsoredLogoUploader

  has_many :ads, -> { order(created_at: :asc) }, dependent: :destroy
  belongs_to :campaign

  enum content_type: {
      list: 0,
      carousel: 1,
      carousel_overlay: 2,
      single_ad: 3,
      lead_gen: 4,
      single_ad_scroll: 5,
      lead_gen_scroll: 6
  }

  validates :name, :content_type, :sizes, :campaign_id, presence: true
  validates :name, length: { maximum: 128 }
  validates :sponsored_label, length: { maximum: 32 }

  scope :ordered, -> { order(created_at: :desc) }

  def ads_minimum_count(size)
    ADS_MINIMUM_COUNT[self[:content_type]][size]
  end

  def loaded_ads_count(size)
    if not_carousel_type
      ADS_MINIMUM_COUNT[self[:content_type]][size.to_i]
    else
      sequence ? ads.count : CAROUSEL_LOADED_ADS_COUNT[size.to_i]
    end
  end

  def showed_ads_count(size)
    not_carousel_type ? ADS_MINIMUM_COUNT[self[:content_type]][size.to_i] : CAROUSEL_SHOWED_ADS_COUNT[size.to_i]
  end

  def carousel_type
    carousel? || carousel_overlay?
  end

  def not_carousel_type
    list? || single_ad_type? || lead_gen_type?
  end

  def not_amp_type
    list? || single_ad_type? || lead_gen_type? || carousel_overlay?
  end

  def narrow_sizes
    sizes & CONTENT_SIZES.keys
  end

  def wide_sizes
    sizes - CONTENT_SIZES.keys
  end

  def content_sizes
    sizes.map { |size| content_sizes_by_type[size] }
  end

  def image_cropped_version_sizes
    if single_ad?
      type_image_sizes(SINGLE_AD_IMAGE_SIZES)
    elsif lead_gen?
      type_image_sizes(LEAD_GEN_IMAGE_SIZES)
    elsif single_ad_scroll?
      type_image_sizes(SINGLE_AD_SCROLL_IMAGE_SIZES)
    elsif lead_gen_scroll?
      type_image_sizes(LEAD_GEN_SCROLL_IMAGE_SIZES)
    else
      %w(300x250)
    end
  end

  def content_size(size)
    content_sizes_by_type[size.to_s]
  end

  def advertiser_name
    campaign.advertiser.name
  end

  def encoded_id
    hashids = Hashids.new(Rails.application.secrets.hash_ids_salt, 16)
    hashids.encode(id)
  end

  def can_be_published?
    min_counts = ADS_MINIMUM_COUNT[self[:content_type]]
    ads.to_publish.count >= sizes.map { |size| min_counts[size.to_i] }.max
  end

  def can_has_video?
    carousel? || carousel_overlay? || single_ad_type? || lead_gen_type?
  end

  def can_include_like_share?
    carousel? || carousel_overlay? || single_ad? || single_ad_scroll? || lead_gen_scroll?
  end

  def self.find_by_hashid(id)
    hashids = Hashids.new(Rails.application.secrets.hash_ids_salt, 16)
    decrypted_id = hashids.decode(id).first
    find(decrypted_id)
  end

  def default_ad
    ads.to_publish.find_by(default: true)
  end

  def copy
    ad_unit = dup
    ad_unit.name = "#{name} (copy)"
    ad_unit.published_at = nil
    ad_unit.sponsored_logo = sponsored_logo
    ad_unit.save

    ads.each do |ad|
      ad = ad.copy
      ad.ad_unit_id = ad_unit.id
      ad.save
    end
    ad_unit.update(sequence_ids: ad_unit.ads&.ids)

    ad_unit
  end

  def create_current_reports
    sizes.each do |s|
      if AdUnitCurrentReport.find_by(ad_unit_id: id, size: s.to_i, content_type: self[:content_type]).nil?
        AdUnitCurrentReport.create(ad_unit_id: id, size: s.to_i, content_type: self[:content_type],
                                   data: DEFAULT_DATA, inserted_at: DateTime.now)
      end
    end
    ads.each do |ad|
      if CurrentReport.find_by(ad_id: ad.id).nil?
        CurrentReport.create(ad_id: ad.id, data: DEFAULT_DATA, inserted_at: DateTime.now)
      end
    end
  end

  def sequence_ads
    sequence_ids.compact.collect { |i| Ad.find(i) }
  end

  def sequence_ads_to_publish
    sequence_ids.compact.collect { |i| Ad.to_publish.where(id: i).first }.compact
  end

  def document_type
    amp ? 'AMP' : 'HTML5'
  end

  def is_vertical?(content_size)
    VERTICAL_CAROUSEL_SIZES.include? content_size
  end

  def lead_gen_type?
    lead_gen? || lead_gen_scroll?
  end

  def single_ad_type?
    single_ad? || single_ad_scroll?
  end

  def scroll_type?
    single_ad_scroll? || lead_gen_scroll?
  end

  private

  def content_sizes_by_type
    if content_type.present?
      "AdUnit::#{content_type.upcase}_CONTENT_SIZES".constantize
    else
      AdUnit::CONTENT_SIZES
    end
  end

  def sizes_sanitization
    sanitized_sizes = content_sizes_by_type.keys.each_with_object([]) do |size, a|
      a << size.to_s if sizes.include?(size.to_s)
    end
    self.sizes = sanitized_sizes.empty? ? nil : sanitized_sizes
  end

  def set_defaults
    self.sponsored_logo = sponsored_logo.presence || campaign.advertiser.logo.presence
    self.sponsored_logo = sponsored_logo.presence || Rails.root.join('public', 'images', 'fallback', 'default_sponsored_logo.png').open
  end

  def edit_ads
    if sizes_changed?
      ads.each do |ad|
        ad.update_video_type
      end
    elsif content_type_changed?
      ads.each do |ad|
        ad.update_content_type

        ad.send("edit_for_#{content_type}")
        ad.save
      end
    end
  end

  def type_image_sizes(type_hash)
    image_sizes = content_sizes.map { |size| type_hash[size] }.uniq
    image_sizes.sort_by do |size|
      case size
      when '300x250'
        0
      when '300x150'
        1
      when '300x90'
        2
      when '250x90'
        3
      end
    end
  end
end
