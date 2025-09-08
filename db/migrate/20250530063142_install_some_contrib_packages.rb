class InstallSomeContribPackages < ActiveRecord::Migration[8.0]
  def up
    unless Rails.env.test?
      execute "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;"
      execute "CREATE EXTENSION IF NOT EXISTS pg_bigm;"
    end
  end

  def down
    unless Rails.env.test?
      execute "DROP EXTENSION IF EXISTS fuzzystrmatch;"
      execute "DROP EXTENSION IF EXISTS pg_bigm;"
    end
  end
end
