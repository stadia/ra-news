class ArticleResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :title
  attribute :title_ko, index: true
  attribute :slug, index: true
  attribute :deleted_at, index: true
  attribute :created_at, form: false
  attribute :host, index: true

  attribute :url, index: false
  attribute :updated_at, form: false
  attribute :summary_key, index: false, form: false
  attribute :summary_detail, index: false, form: false
  attribute :published_at
  attribute :origin_url, index: false
  attribute :tag_list, index: false

  # Associations
  attribute :user, index: false, form: false
  attribute :site, index: false, form: false

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
