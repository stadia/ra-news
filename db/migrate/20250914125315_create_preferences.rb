class CreatePreferences < ActiveRecord::Migration[8.0]
  def up
    create_table :preferences do |t|
      t.string :name
      t.jsonb :value, default: {}
      t.timestamps
    end

    Preference.create(name: 'ignore_hosts', value: %w[example.com localhost])
  end

  def down
    drop_table :preferences
  end
end
