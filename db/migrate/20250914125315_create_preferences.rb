class CreatePreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :preferences do |t|
      t.string :key
      t.jsonb :value, default: {}
      t.timestamps
    end
  end
end
