class BackfillFederailsActorsForExistingUsers < ActiveRecord::Migration[8.1]
  def up
    User.find_each do |user|
      next if Federails::Actor.exists?(entity: user)

      Federails::Actor.find_or_create_by!(entity: user) do |actor|
        actor.local = true
      end
    end
  end

  def down
  end
end
