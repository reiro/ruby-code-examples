module ApplicationHelper
  def nav_link(link_text, link_path)
    class_name = current_page?(link_path) ? 'active' : ''

    content_tag(:li, class: class_name) do
      link_to link_text, link_path
    end
  end

  def namespace
    controller_path.split('/').first
  end

  def user_title(user = current_user)
    user.full_name.presence || user.email
  end

  def human_boolean(boolean)
    t("booleans.#{boolean}")
  end

  def circle_btn(title: t('add_new'), icon: 'md-add', klass: 'btn-primary')
    content_tag(:div, class: "btn btn-round btn-lg #{klass}",
                 data: { toggle: 'tooltip ' }, title: title
               ) do
      content_tag(:i, '', class: "md #{icon}")
    end
  end

  def something_to_percentage(number)
    corrected_number = if number.is_a?(Float)
                         number * 100
                       else
                         number.to_i
                       end
    number_to_percentage(corrected_number, precision: 2)
  end

  def date_range_params
    {
      fast_choice: params[:fast_choice],
      date_from: params[:date_from],
      date_to: params[:date_to],
      source: params[:source]
    }
  end

  def question_icon(title)
    "<i data-toggle='tooltip' data-placement='top' title='#{title}' class='md-help'></i>".html_safe
  end

  def brand_logo
    organization =
      if current_user.belongs_to_advertiser?
        advertiser = current_user.manageable
        advertiser.logo_url ? advertiser : (advertiser.agency || advertiser.publisher)
      elsif current_user.belongs_manageable?
        current_user.manageable
      end
    image_tag(organization&.logo_url || 'new_enzymic_logo.png')
  end

  def edit_organization_path
    organization = current_user.manageable
    case organization.class.name
    when 'Agency'
      edit_agency_path(organization)
    when 'Publisher'
      edit_publisher_path(organization)
    when 'Advertiser'
      edit_advertiser_path(organization)
    end
  end

  USUAL_ASSET = {
      jquery: 'https://ajax.googleapis.com/ajax/libs/jquery/1.12.2/jquery.min.js',
      enabler: 'https://s0.2mdn.net/ads/studio/Enabler.js',
      aol: 'https://secure-ads.pictela.net/rm/lib/richmedia/core-dev/1_12/ADTECH.js',
      nexus: 'https://acdn.adnxs.com/html5-lib/1.3.0/appnexus-html5-lib.min.js',
      sizmek: 'https://secure-ds.serving-sys.com/BurstingScript/EBLoader.js'
  }

  CHINA_ASSET = {
      jquery: 'https://imagecdn.enzymic.co/js/jquery.min.js',
      enabler: 'https://imagecdn.enzymic.co/js/enabler.js',
      aol: 'https://imagecdn.enzymic.co/js/aol.js',
      nexus: 'https://imagecdn.enzymic.co/js/nexus.js',
      sizmek: 'http://imagecdn.enzymic.co/js/sizmek.js'
  }

  def asset_cdn_url(name)
    session[:country] == 'CN' ? CHINA_ASSET[name] : USUAL_ASSET[name]
  end

  def ad_asset_type(ad)
    ad.video? && session[:country] != 'CN' ? 'video_' : ''
  end
end
