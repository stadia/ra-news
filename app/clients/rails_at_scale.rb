class RailsAtScale < ApplicationClient
  BASE_URI = "https://railsatscale.com"

  def feed #? RSS::Atom::Feed
    RSS::Parser.parse(get("/feed.xml").body)
  end
end
