class Article < ApplicationRecord
  belongs_to :user, optional: true

  after_create :generate_title

  def generate_title
    response = Faraday.get(url)
    if response.status == 301
      update(url: response.headers["location"])
      response = Faraday.get(url)
    end
    doc = Nokogiri::HTML(response.body)
    title = doc.at("title").text
    update(title:) if title.is_a?(String)
  end
end
