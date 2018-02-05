module CommonSupport
  extend ActiveSupport::Concern

  included do
    before_action :check_china, only: [:show, :edit, :index, :new]
  end

  def admin?
    controller_path.starts_with?('administrator')
  end

  def advertisers_manager?
    admin? || current_user.belongs_manageable?
  end

  def path(path, *params)
    path_with_context = admin? ? admin_path(path.to_s) : path
    send("#{path_with_context}_path", *params)
  end

  private

  def campaigns
    if admin?
      Campaign
    else
      owner = current_user.belongs_manageable? ? current_user.manageable : current_user
      owner.campaigns
    end
  end

  def ad_units
    AdUnit.where(campaign_id: campaigns.ids)
  end

  def ads
    Ad.where(ad_unit_id: ad_units.ids)
  end

  def leads
    Lead.where(ad_id: ads.ids)
  end

  def advertisers
    admin? ? Advertiser.all : current_user.manageable.advertisers
  end

  def admin_path(path)
    if path.starts_with?('new', 'edit', 'publish', 'copy')
      parts = path.partition('_')
      "#{parts.first}_administrator_#{parts.last}"
    else
      "administrator_#{path}"
    end
  end

  def check_china
    ip = request.remote_ip
    session[:country] =
        if (ip =~ Resolv::IPv4::Regex) || (ip =~ Resolv::IPv6::Regex)
          CidrToCountry.find_by(':ip <<= network', ip: ip)&.country
        else
          nil
        end
  end
end
