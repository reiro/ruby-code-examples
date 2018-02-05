module DashboardHelper
  PERCENTAGE_MAX_LIMIT = 200
  NUMBER_MIN_LIMIT = 10
  CTR_MULTIPLIER = 100
  COLORS = %w(#67b7dc #84b761 #fdd400 #cc4748 #cd82ad #2f4074 #448e4d #b7b83f).freeze
  VIDEO_EVENT_TYPES = %w(5s_views 50%_views 100%_views).freeze
  SHARE_EVENT_TYPES = %w(likes tw_shares fb_shares in_shares wa_shares email_shares).freeze
  Y_AXIS_IDS = %w(A B C).freeze

  def trend_chart_data(analytics)
    analytics.each { |r| r[:ctr] = ctr_with_multiplier(r) }
    {
      labels: trend_chart_labels(analytics),
      datasets: chart_datasets(analytics, COLORS[0])
    }
  end

  def performance_chart_data(records_with_analytics, record_label)
    labels =
      if params[:controller].ends_with?('dashboard/ad_units') && params[:source] == 'ad_unit'
        records_with_analytics.each { |r| r[:ctr] = ctr_with_multiplier(r) }
        records_with_analytics.sort_by! { |r| r[:ctr] }.reverse!
        sizes_labels(records_with_analytics)
      else
        records_with_analytics.each { |r| r.analytics[:ctr] = ctr_with_multiplier(r.analytics) }
        records_with_analytics.sort_by! { |r| r.analytics[:ctr] }.reverse!
        records_with_analytics.map { |r| "#{record_label} #{r.id}" }
      end
    {
      labels: labels,
      datasets: chart_datasets(records_with_analytics, COLORS[1])
    }
  end

  def video_performance_chart_data(records_with_analytics, record_label)
    labels =
      if params[:controller].ends_with?('dashboard/ad_units') && params[:source] == 'ad_unit'
        records_with_analytics.sort_by! { |r| r[:'5s_views'] }.reverse!
        sizes_labels(records_with_analytics)
      else
        records_with_analytics.sort_by! { |r| r.analytics[:'5s_views'] }.reverse!
        records_with_analytics.map { |r| "#{record_label} #{r.id}" }
      end
    {
      labels: labels,
      datasets: video_chart_datasets(records_with_analytics)
    }
  end

  def donut_chart_data(analytics)
    {
      labels: analytics.keys,
      datasets: [
        {
          data: values(analytics.values, :impressions),
          backgroundColor: COLORS,
          hoverBackgroundColor: COLORS
        }
      ]
    }
  end

  def donut_color(index)
    COLORS[index % COLORS.length]
  end

  def prepare_analytics(records, method = :analytics)
    records.each { |r| r.send(method)[:ctr] = ctr(r.send(method)) }
    records.each { |r| r.send(method)[:engagement_rate] = engagement_rate(r.send(method)) }
    records.sort_by { |r| r.send(method)[:ctr] if r.send(method) }.reverse
  end

  def ctr(analytics)
    analytics[:impressions].zero? ? 0 : analytics[:clicks].to_f / analytics[:impressions]
  end

  def engagement_rate(analytics)
    analytics[:impressions].zero? ? 0 : (analytics[:swipes].to_f + analytics[:clicks].to_f) / analytics[:impressions]
  end

  def rr(analytics)
    analytics[:impressions].zero? ? 0 : analytics[:submits].to_f / analytics[:impressions]
  end

  private

  def chart_datasets(records_with_analytics, color)
    [
      {
        type: 'line',
        lineTension: 0,
        label: 'CTR (%)',
        backgroundColor: 'rgba(151, 187, 205, 0)',
        borderColor: 'rgba(255, 0, 0, 0.5)',
        yAxisID: Y_AXIS_IDS[0],
        data: values(records_with_analytics, :ctr)
      },
      {
        label: 'Impression',
        backgroundColor: "rgba(#{rgba(color)}, 0.7)",
        borderColor: "rgba(#{rgba(color)}, 0.8)",
        yAxisID: Y_AXIS_IDS[1],
        data: values(records_with_analytics, :impressions)
      }
    ]
  end

  def video_chart_datasets(records_with_analytics)
    VIDEO_EVENT_TYPES.map.with_index do |key, index|
      color = COLORS[index]
      {
        label: key.humanize,
        backgroundColor: "rgba(#{rgba(color)}, 0.7)",
        borderColor: "rgba(#{rgba(color)}, 0.8)",
        yAxisID: Y_AXIS_IDS[index],
        data: values(records_with_analytics, key.to_sym)
      }
    end
  end

  def trend_chart_labels(analytics)
    case params[:period_type].to_sym
    when :month
      analytics.compact.map { |r| r[:date_from].strftime('%b') }
    else
      analytics.compact.map { |r| r[:date_from].strftime('%d %b') }
    end
  end

  def chart_options(data)
    max_a = [round_up(data[:datasets][0][:data].max), PERCENTAGE_MAX_LIMIT].min
    max_b = [round_up(data[:datasets][1][:data].max), NUMBER_MIN_LIMIT].max
    {
      height: 300,
      width: 800,
      scales: {
        yAxes: [
          {
            id: Y_AXIS_IDS[0],
            ticks: { min: 0, max: max_a, stepSize: max_a / 10.0 }
          },
          {
            id: Y_AXIS_IDS[1],
            position: 'right',
            ticks: { min: 0, max: max_b, stepSize: max_b / 10 }
          },
        ]
      }
    }
  end

  def video_chart_options(data)
    max = [round_up(data[:datasets].map { |d| d[:data].max }.max), NUMBER_MIN_LIMIT].max
    ticks = { min: 0, max: max, stepSize: max / 10 }
    {
      height: 300,
      width: 800,
      scales: {
        yAxes: [
          {
            id: Y_AXIS_IDS[0],
            ticks: ticks
          },
          {
            id: Y_AXIS_IDS[1],
            position: 'right',
            ticks: ticks
          },
          {
            id: Y_AXIS_IDS[2],
            display: false,
            ticks: ticks
          }
        ]
      }
    }
  end

  def donut_chart_options
    {
      height: 200,
      width: 200
    }
  end

  def round_up(num)
    return 1 if num.blank? || num.zero?
    return num * 2 if num < 1
    num += 1
    x = Math.log10(num).floor
    (num / (10.0**x)).ceil * 10**x
  end

  def values(records_with_analytics, key)
    records_with_analytics.compact.map { |r| r[key] || r.analytics[key] }
  end

  def ctr_with_multiplier(analytics)
    (ctr(analytics) * CTR_MULTIPLIER).round(2)
  end

  def sizes_labels(records)
    if records.map { |r| r[:content_type] }.uniq.count > 1
      records.map do |r|
        ad_unit = AdUnit.new(content_type: r[:content_type])
        content_type = AdUnit.human_attribute_name("content_types.#{ad_unit.content_type}")
        content_size = ad_unit.content_size(r[:size])
        "#{content_type} #{content_size}"
      end
    else
      ad_unit = AdUnit.new(content_type: records.first[:content_type])
      records.map { |r| ad_unit.content_size(r[:size]) }
    end
  end

  def ad_sizes_analytics
    calculate_donut_analytics { |r| AdUnit.new(content_type: r[:content_type]).content_size(r[:size]) }
  end

  def content_types_analytics
    calculate_donut_analytics do |r|
      AdUnit.human_attribute_name("content_types.#{AdUnit.new(content_type: r[:content_type]).content_type}")
    end
  end

  def calculate_donut_analytics
    analytics = @reports.each_with_object({}) do |r, h|
      key = yield(r)
      element = h[key] ||= { impressions: 0, clicks: 0 }
      element[:impressions] += r[:impressions]
      element[:clicks] += r[:clicks]
    end
    analytics.each do |_, r|
      r[:ctr] = something_to_percentage(ctr(r))
      r[:engagement_rate] = something_to_percentage(engagement_rate(r))
    end
    analytics.sort_by { |_, r| r[:ctr] }.reverse.to_h
  end

  def rgba(color)
    color[1..-1].scan(/.{2}/).map { |c| c.to_i(16) }.join(',')
  end

  def campaigns_dashboard?
    controller_path.ends_with?('campaigns') && action_name == 'index'
  end

  def export_url
    request.path + ".xlsx?source=#{params[:source]}&period_type=#{params[:period_type]}&advertiser_id=#{params[:advertiser_id]}&date_from=#{params[:date_from]}&date_to=#{params[:date_to]}"
  end
end
