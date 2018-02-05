class ImageSpider
  MIN_WIDTH = 300
  MIN_HEIGHT = 200
  VALID_IMAGE_TYPES = [:gif, :png, :jpg, :jpeg].freeze
  IMAGE_SOURCE_TYPES = [:html, :meta, :js].freeze

  def initialize(url)
    @url = url
    @base_url = URI.join(url, '/').to_s if url_valid?
  end

  def fetch_images
    fetched_images if url_valid?
  end

  def fetch_title
    fetched_title if url_valid?
  end

  def fetch_description
    fetched_description if url_valid?
  end

  def url_valid?
    @url =~ URI.regexp
  end

  private

  def image_url(image_src)
    image_src = URI.escape(image_src.strip)
    URI.join(@base_url, image_src).to_s
  end

  def fetched_images
    selected_images.map do |image_src|
      image_url(image_src)
    end
  end

  def fetched_title
    raw.css('title').text
  end

  def fetched_description
    raw.css("meta[name='description']/@content").text
  end

  def selected_images
    @selected_images ||= valid_images
  end

  def valid_images
    images = []
    IMAGE_SOURCE_TYPES.each do |type|
      images |= images_sources(type).select do |img_src|
        img_src = image_url(img_src)
        img_src if image_valid?(img_src)
      end
      return images if type == :meta && images.present?
    end
    images
  end

  def image_valid?(img_src)
    image = FastImage.new(img_src)
    image_size = image.size
    image_type = image.type

    image_size && image_size[0] > MIN_WIDTH &&
      image_size[1] > MIN_HEIGHT &&
      VALID_IMAGE_TYPES.include?(image_type)
  end

  def images_sources(type)
    raw_images(type).map { |img| img[:src] || img[:srcset] || img.value }.compact.uniq
  end

  def raw_images(type)
    case type
    when :html
      raw.css('img')
    when :meta
      raw.css("meta[property='og:image']/@content")
    when :js
      load_images_by_js
    end
  end

  def load_images_by_js
    browser = Capybara.current_session
    browser.visit @url
    browser.all('img')
  end

  def raw
    @raw ||= Nokogiri::HTML(body)
  end

  def body
    @body ||= request.body_str
  end

  def request
    @request ||= Curl.get(@url)
  end
end
