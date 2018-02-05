module TitleHelper
  def title(text)
    content_for :title do
      full_title(text)
    end
    text
  end

  def full_title(text)
    title = 'Adzymic'
    title = "Admin | #{title}" if admin?
    title = "#{title} - #{text}" unless text.empty?
    title
  end
end
