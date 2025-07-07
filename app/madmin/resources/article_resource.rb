class ArticleResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :title
  attribute :title_ko, index: true
  attribute :slug, index: true
  attribute :deleted_at, index: true
  attribute :created_at, form: false
  attribute :host, index: true
  attribute :is_related, index: true

  attribute :url, index: false
  attribute :updated_at, form: false
  attribute :summary_key, index: false, form: false
  attribute :summary_detail, index: false, form: false
  attribute :published_at
  attribute :origin_url, index: false
  attribute :tag_list, index: false
  attribute :is_youtube, index: false
  attribute :body, index: false, form: true

  # Associations
  attribute :user, index: false, form: false
  attribute :site, index: true, form: false

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  member_action do |record|
    if record.is_a?(Article) && record.deleted_at.nil?
      button_to "Discard", discard_madmin_article_path(record), method: :put, data: { turbo_confirm: "Are you sure you want to discard this article?" },
    class: "btn btn-danger bg-red-600 text-white rounded px-4 py-2 hover:bg-red-700"
    else
      button_to "Restore", restore_madmin_article_path(record), method: :put, data: { turbo_confirm: "Are you sure you want to restore this article?" },
    class: "btn btn-success bg-green-600 text-white rounded px-4 py-2 hover:bg-green-700"
    end
  end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
