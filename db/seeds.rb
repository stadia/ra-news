# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
Role.find_or_create_by!(name: "user")
Role.find_or_create_by!(name: "admin")
Role.find_or_create_by!(name: "bot")

admin = User.find_or_initialize_by(email: "admin@example.com") do |user|
  user.password = "admin123"
  user.name = "Admin"
  user.roles = [ "user", "admin" ]
end
admin.confirmed_at ||= Time.current
admin.save!

Preference.find_or_create_by!(name: "ignore_hosts") do |preference|
  preference.value = []
end

Preference.find_or_create_by!(name: "slack_oauth") do |preference|
  preference.value = { client_id: "", client_secret: "", signing_secret: "" }
end

Preference.find_or_create_by!(name: "web_push") do |preference|
  preference.value = { public_key: "", private_key: "", subject: "" }
end
