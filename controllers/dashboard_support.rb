module DashboardSupport
  extend ActiveSupport::Concern

  included do
    before_action :set_default_params
    before_action :fetch_advertisers
  end

  private

  CUSTOM_FAST_CHOICE = 5
  DEFAULT_SOURCE = 'ad_unit'

  def get_records_with_analytics(one_page_records, total_records)
    Kaminari.paginate_array(
      Analytics::Fetcher.new(one_page_records, date_range, params[:source]).fetch,
      total_count: total_records
    ).page(params[:page])
  end

  def date_range
    { date_from: params[:date_from], date_to: params[:date_to] }
  end

  def date_range_for_period(start_date, type)
    { date_from: to_s(start_date), date_to: to_s(start_date + 1.send(type) - 1.day) }
  end

  def to_s(date)
    date.strftime '%d-%m-%Y'
  end

  def periods(type)
    date_from  = Date.parse(params[:date_from])
    date_to    = Date.parse(params[:date_to])
    date_range = date_from..date_to
    case type.to_sym
    when :month
      date_range.map { |d| Date.new(d.year, d.month, 1) }.uniq
    when :week
      date_range.select(&:sunday?)
    when :day
      date_range.to_a
    end
  end

  def sum_values(records, key)
    records.inject(0) { |sum, r| sum + (r[key] || r.analytics[key]) }
  end

  def set_default_params
    @time_zone = current_user ? current_user.time_zone : 'Asia/Singapore'
    params[:fast_choice] ||= CUSTOM_FAST_CHOICE
    params[:date_to] ||= to_s(Time.now.in_time_zone(@time_zone).to_date)
    params[:period_type] ||= :week
    params[:source] ||= DEFAULT_SOURCE
  end

  def ad_sizes_analytics
    analytics = @reports.each_with_object({}) do |r, h|
      content_size = AdUnit.new(content_type: r[:content_type]).content_size(r[:size])
      element = h[content_size] ||= { impressions: 0, clicks: 0 }
      element[:impressions] += r[:impressions]
      element[:clicks] += r[:clicks]
      element[:submits] += r[:submits]
    end
    analytics.each do |_, r|
      r[:ctr] = something_to_percentage(ctr(r))
      r[:engagement_rate] = something_to_percentage(engagement_rate(r))
    end
    analytics.sort_by { |_, r| r[:ctr] }.reverse
  end

  def fetch_advertisers
    @advertisers = advertisers if advertisers_manager?
  end
end
