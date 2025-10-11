class CreatePreferences < ActiveRecord::Migration[8.0]
  def up
    create_table :preferences do |t|
      t.string :name
      # Use json for SQLite compatibility, jsonb for PostgreSQL
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        t.jsonb :value, default: {}
      else
        t.json :value, default: {}
      end
      t.timestamps
    end

    Preference.create(name: 'ignore_hosts', value: %w[example.com localhost])
  end

  def down
    drop_table :preferences
  end
end
