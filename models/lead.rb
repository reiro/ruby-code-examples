# == Schema Information
#
# Table name: leads
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  fields        :jsonb
#  custom_fields :jsonb
#  ad_id         :integer
#

class Lead < ActiveRecord::Base
  belongs_to :ad

  scope :ordered, -> { order(created_at: :desc) }

  def self.custom_fields_names(ad)
    ad.leads.map { |q| q.custom_fields&.keys }.flatten.uniq.compact
  end

  def self.header_attrs(ad)
    attributes = %w{id ad_id created_at}
    attributes.insert(2, LeadForm.fields_names).flatten!
    attributes.insert(-2, custom_fields_names(ad)).flatten!
    attributes << 'Opt_in'
    attributes
  end

  def row_values
    values = [id, ad_id, created_at]
    values.insert(2, LeadForm.fields_names.map { |field| fields[field] }).flatten!
    values.insert(-2, Lead.custom_fields_names(ad).map { |field| custom_fields[field] if custom_fields }).flatten!
    values << opt_in
  end

  def self.to_csv(ad)
    CSV.generate do |csv|
      csv.add_row header_attrs(ad)
      all.each do |lead|
        csv.add_row lead.row_values
      end
    end
  end
end
