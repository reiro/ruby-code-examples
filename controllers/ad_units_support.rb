module AdUnitsSupport
  extend ActiveSupport::Concern

  included do
    before_action :fetch_campaign
    before_action :fetch_ad_unit, only: [:show, :edit, :update, :destroy, :publish, :copy, :update_sequence]
    before_action :fetch_ads, only: [:show]
  end

  def show
  end

  def new
    @ad_unit = AdUnit.new
  end

  def create
    @ad_unit = AdUnit.new(ad_unit_params)
    @ad_unit.campaign = @campaign

    if @ad_unit.save
      redirect_to path(:campaign_ad_unit, @campaign, @ad_unit), notice: t('concerns.ad_units_support.create.notice')
    else
      render :new
    end
  end

  def update
    if @ad_unit.update(ad_unit_params)
      @ad_unit.ads.update_all(updated_at: DateTime.now)
      redirect_to path(:campaign_ad_unit, @campaign, @ad_unit), notice: t('concerns.ad_units_support.update.notice')
    else
      render :edit
    end
  end

  def destroy
    @ad_unit.destroy
    redirect_to path(:campaign, @campaign), notice: t('concerns.ad_units_support.destroy.notice')
  end

  def publish
    return unless @ad_unit.can_be_published?

    content_sizes = @ad_unit.content_sizes
    tag = DoubleclickTag.new(@ad_unit, params[:network].to_sym)
    @js_tags = tag.publish_tag_files.map.with_index do |content, index|
      {
        content: content,
        size: content_sizes[index]
      }
    end
    @ad_unit.create_current_reports
    AdUnitScreenshotsJob.perform_later(@ad_unit, @ad_unit.encoded_id, request.base_url)
    @ad_unit.ads.ready_to_publish.update_all(status: Ad.statuses[:published])

    render layout: nil
  end

  def copy
    @ad_unit = @ad_unit.copy
    redirect_to path(:campaign_ad_unit, @campaign, @ad_unit), notice: t('concerns.ad_units_support.copy.notice')
  end

  def update_sequence
    @ad_unit.update(sequence_ids: params[:sequence_ids])
    render nothing: true, status: 200, content_type: 'text/html'
  end

  private

  def fetch_ad_unit
    @ad_unit = @campaign.ad_units.find(params[:id])
  end

  def fetch_campaign
    @campaign = campaigns.find(params[:campaign_id])
  end

  def fetch_ads
    @ads = @ad_unit.sequence ? @ad_unit.sequence_ads : @ad_unit.ads
  end

  def ad_unit_params
    params.require(:ad_unit).permit(
      :name,
      :content_type,
      :sponsored_label,
      :sponsored_logo,
      :sponsored_logo_cache,
      :remove_sponsored_logo,
      :auto_optimization,
      :sequence,
      :amp,
      sizes: []
    )
  end
end
