module AdsHelper
  AD_UNIT_SIZES_BY_IMAGE_SIZE = {
    '300x150' => %w(300x250),
    '300x250' => %w(300x600 970x250 320x480),
    '250x90' => %w(728x90),
    '300x90' => %w(970x90)
  }.freeze

  MARGIN_FIELD_HEIGHT = 7.freeze

  def no_ads
    content_tag :p, t('ads.ads.no_ads'), id: 'no_ads'
  end

  def lead_form_fields_data(f)
    data = { name: f.name, label: f.label, options: f.options, presence: f.presence, type: f.type }
    content_tag :div, nil, class: 'lead_field', data: data
  end

  def image_preview(size)
    case @ad_unit.content_type
    when 'list'
      @ad.image.cropped.url
    when 'carousel'
      @ad.image.carousel.url
    when 'carousel_overlay'
      @ad.image.size_300x250.url
    when 'single_ad', 'single_ad_scroll'
      single_ad_image_preview(size)
    when 'lead_gen', 'lead_gen_scroll'
      @ad.image.size_300x150.url
    end
  end

  def single_ad_image_preview(size)
    @ad.image.send("size_#{size}").url
  end

  def ad_image_title(image_size)
    AD_UNIT_SIZES_BY_IMAGE_SIZE[image_size].join(', ')
  end

  def ad_statuses
    @ad.published? ? %w(published ready_to_publish unpublished) : %w(ready_to_publish unpublished)
  end

  def button_style(ad)
    style = "background-color: #{ad.button_color};"
    ad.button_color == '#ffffff' ? style + "border: 1px solid #b0b0b0;" : style + "color: white; font-weight: bold;"
  end

  def submit_value(ad, size)
    ad.has_action? && ad.ad_unit.is_vertical?(size) ? ad.action_text : 'Submit'
  end

  def has_errors?
    @ad.errors.any? || @ad.video&.errors&.any? || @ad.lead_form&.errors&.any?
  end

  def ad_form_template
    @ad.ad_unit.lead_gen_type? ? 'ads/lead_form' : 'ads/form'
  end

  def overlay_img_class(ad)
    if ad.shade?
      'shade'
    elsif ad.transparent?
      'transparent'
    end
  end

  def increase_field_height(field)
    fieldHeight = case field.type
                  when 'text', 'email', 'tel', 'select'
                    field.label.length > 10 ? 37 : 21
                  when 'radio', 'checkbox'
                    field.label.length > 10 ? 32 : 16
                  end
    MARGIN_FIELD_HEIGHT + fieldHeight
  end

  def build_field(field)
    res = []
    case field.type
    when 'text', 'email', 'tel'
      res << "<div class='form-group text-input'>"
        res << "<label>#{field.label}</label>"
        res << "<input type='#{field.type}' name='#{field.name}' id='#{field.name}'>"
      res << "</div>"
    when 'radio'
      res << "<div class='form-group radio-input'>"
        res << "<label>#{field.label}</label>"
        res << "<div class='radio-inline'>"
          field.options.each do |option|
            res << "<label class='filled'>"
              res << "<input name='#{field.name}' type='radio' value='#{option}'>"
            res << "#{option}</label>"
          end
        res << "</div>"
      res << "</div>"
    when 'select'
      res << "<div class='form-group select-input'>"
        res << "<label>#{field.label}</label>"
        res << "<select class='form-control' name='#{field.name}' id='#{field.label}'>"
          res << "<option></option>"
          field.options.each do |option|
            res << "<option value='#{option}'>#{option}</option>"
          end
        res << "</select>"
      res << "</div>"
    when 'checkbox'
      res << "<div class='form-group checkbox-input'>"
        res << "<label>#{field.label}</label>"
        res << "<div class='checkbox-inline'>"
        field.options.each do |option|
          res << "<label class='filled'>"
            res << "<input name='#{field.name}' type='checkbox' value='#{option}'>"
          res << "#{option}</label>"
        end
        res << "</div>"
      res << "</div>"
    end
    res.join('')
  end

  def is_last_step?(fields, i, lead_form_step_height, current_fields_count, fields_limit)
    sum = fields[i..fields.count].sum { |f| increase_field_height(f) }
    if fields.count - current_fields_count <= fields_limit && sum <= lead_form_step_height
      true
    else
      false
    end
  end

  def build_steps(fields, ad_unit_size)
    case ad_unit_size
    when '300x250'
      lead_form_step_height = 140
      lead_form_last_step_height = 137
      fields_limit = 5
    when '300x600'
      lead_form_step_height = 230
      lead_form_last_step_height = 185
      fields_limit = 6
    when '320x480'
      lead_form_step_height = 144
      lead_form_last_step_height = 112
      fields_limit = 4
    end

    res = []
    current_step = 0
    total_step = 0
    fields_count = 0
    step_height = 0
    should_open_step = true
    is_last_step = false

    fields.each_with_index do |field, i|
      if should_open_step
        res << "<div class='form_step' id='#{current_step}'>"
        current_step += 1
        should_open_step = false
        is_last_step = is_last_step?(fields, i, lead_form_step_height, total_step, fields_limit)
      end

      res << build_field(field)

      fields_count += 1
      total_step += 1
      last_field = fields.count == i + 1
      step_height += increase_field_height(field)
      next_field_height = last_field ? 0 : increase_field_height(fields[i + 1])
      height_limit = is_last_step ? lead_form_last_step_height : lead_form_step_height
      if (step_height + next_field_height) > height_limit || last_field || fields_count >= fields_limit
        res << "</div>"
        should_open_step = true
        step_height = 0
        fields_count = 0
      end
    end

    res.join('')
  end

  def can_has_video?(content_type)
    ['carousel', 'carousel_overlay', 'single_ad', 'lead_gen', 'single_ad_scroll', 'lead_gen_scroll'].include?(content_type)
  end

  def can_include_like_share?(content_type)
    ['carousel', 'carousel_overlay', 'single_ad', 'single_ad_scroll', 'lead_gen_scroll'].include?(content_type)
  end

  def desc_style_limit(ad)
    ad.title.length <= Ad::CAROUSEL_TITLE_ONE_LINE_LIMIT ? 'max-height: 3.6em;' : ''
  end

  def hide_video_option?(option)
    if option == :infini
      !@ad_unit.content_sizes.include?('300x250') || @ad_unit.content_type != 'single_ad'
    else
      false
    end
  end

  def amp_youtube_video(ad, idx)
    if ad.video.autoplay && @should_autoplay
      @should_autoplay = false
      content_tag(:'amp-youtube', '', id: "media#{idx + 1}", width: @media_width,
                  autoplay: '', height: @media_height, data: { videoid: ad.video.uid })
    else
      content_tag(:'amp-youtube', '', id: "media#{idx + 1}", width: @media_width,
                  height: @media_height, data: { videoid: ad.video.uid })
    end
  end

  def share_content(ad)
    [ad.title, ad.description, ad.short_url].reject(&:nil?).reject(&:empty?).join(' - ')
  end
end
