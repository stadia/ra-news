class RssClient < ApplicationClient
  def feed(path)
    RSS::Parser.parse(get(path).body)
  end
end