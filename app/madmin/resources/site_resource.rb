class SiteResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :base_uri, index: true
  attribute :email, index: true
  attribute :path, index: true
  attribute :channel, index: true
  attribute :last_checked_at, index: true, form: false

  attribute :client
  attribute :created_at, form: false, index: false
  attribute :updated_at, form: false
  attribute :deleted_at, index: true, form: false

  # Associations
  attribute :articles, form: false

  # Add scopes to easily filter records
  scope :kept
  scope :discarded

  # Add actions to the resource's show page
  member_action do |record|
    if record.is_a?(Site) && record.deleted_at.nil?
      button_to "Discard", discard_madmin_site_path(record), method: :put, data: { turbo_confirm: "Are you sure you want to discard this site?" },
    class: "btn btn-danger bg-red-600 text-white rounded px-4 py-2 hover:bg-red-700"
    else
      button_to "Restore", restore_madmin_site_path(record), method: :put, data: { turbo_confirm: "Are you sure you want to restore this site?" },
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
