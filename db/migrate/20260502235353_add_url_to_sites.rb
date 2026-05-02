class AddUrlToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :url, :string

    reversible do |dir|
      dir.up do
        # 기존 base_uri + path 조합으로 url 역산
        Site.where.not(base_uri: [nil, ""]).find_each do |site|
          site.update_column(:url, [site.base_uri, site.path].compact.join)
        end
      end
    end
  end
end