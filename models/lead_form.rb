# == Schema Information
#
# Table name: lead_forms
#
#  id            :integer          not null, primary key
#  ad_id         :integer
#  fields        :json             not null
#  custom_fields :json             not null
#  privacy_link  :string
#  message       :string
#  description   :string
#  form_title    :string
#  created_at    :datetime
#  updated_at    :datetime
#

# create_table "lead_forms", force: :cascade do |t|
#   t.integer  "ad_id"
#   t.jsonb    "fields",        default: {}, null: false
#   t.jsonb    "custom_fields", default: {}, null: false
#   t.string   "privacy_link"
#   t.string   "message"
#   t.string   "description"
#   t.string   "redirect_url"
#   t.datetime "created_at"
#   t.datetime "updated_at"
# end

class LeadForm < ActiveRecord::Base
  include CountryNames
  belongs_to :ad

  validates :form_title, length: { maximum: 70 }
  validates :privacy_link, length: {
    maximum: 125,
    tokenizer: lambda { |string| ActionController::Base.helpers.strip_tags(string).split(//) },
    message: 'too long. max length is 125'
  }

  DEFAULT_FIELDS = [
    { 'name' => 'salutation', 'label' => 'Salutation', 'type' => 'select', 'options' => %w(Mr. Miss. Mdm.), 'presence' => '1' },
    { 'name' => 'first_name', 'label' => 'First Name', 'type' => 'text', 'options' => {}, 'presence' => '1' },
    { 'name' => 'last_name', 'label' => 'Last Name', 'type' => 'text', 'options' => {}, 'presence' => '1' },
    { 'name' => 'email', 'label' => 'Email', 'type' => 'email', 'options' => {}, 'presence' => '1' },
    { 'name' => 'company', 'label' => 'Company', 'type' => 'text', 'options' => {}, 'presence' => '1' },
    { 'name' => 'gender', 'label' => 'Gender', 'type' => 'radio', 'options' => %w(male female), 'presence' => '1' },
    { 'name' => 'phone', 'label' => 'Phone', 'type' => 'tel', 'options' => {}, 'presence' => '1' },
    { 'name' => 'job_title', 'label' => 'Job Title', 'type' => 'text', 'options' => {}, 'presence' => '1' },
    { 'name' => 'country', 'label' => 'Country', 'type' => 'select', 'options' => CountryNames::COUNTRIES, 'presence' => '1' }
  ].freeze

  def self.fields_names
    DEFAULT_FIELDS.map { |f| f.first[1] }
  end

  def custom_fields_names
    custom_fields.map(&:name)
  end

  def fields
    read_attribute(:fields).map { |f| LeadField.new(f) }
  end

  def custom_fields
    read_attribute(:custom_fields).map { |f| LeadField.new(f) }
  end

  def should_render_fields
    (fields + custom_fields).select { |f| f if f.presence == '1' }
  end

  def build_field
    f = fields.dup
    DEFAULT_FIELDS.each do |field|
      f << LeadField.new(field)
    end
    self.fields = f
  end

  def copy
    lead_form = dup
    lead_form
  end

  class LeadField
    attr_accessor :name, :label, :type, :options, :presence

    def initialize(hash)
      @name = hash['name']
      @label = hash['label']
      @type = hash['type']
      @options = hash['options']
      @presence = hash['presence']
    end
  end
end
