class AddUniqueIndexToPreferencesName < ActiveRecord::Migration[8.1]
  def change
    change_column_null :preferences, :name, false
    add_index :preferences, :name, unique: true
  end
end
