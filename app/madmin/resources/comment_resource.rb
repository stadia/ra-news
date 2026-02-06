class CommentResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :body, index: true
  attribute :lft
  attribute :rgt
  attribute :depth
  attribute :children_count, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :author_name, index: true
  attribute :user_id, index: true

  # Associations
  attribute :parent
  attribute :children
  attribute :article, index: true

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
