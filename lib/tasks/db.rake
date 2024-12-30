require "sqlite3"

namespace :db do
  desc "Removes the database file"
  task :drop do
    environment = ENV["APP_ENV"] || "development"
    data_path = "./db/data/#{environment}.db"
    execute_drop = ENV["DOUBLE_CONFIRM"] == "true"
    database_exists = File.exist?(data_path)

    unless execute_drop
      puts ""
      puts ""
      puts "  >> Database drop was not double-confirmed. Doing nothing."
      puts ""
      puts ""
      next
    end

    unless File.exist?(data_path)
      puts ""
      puts ""
      puts "  >> Database does not exist. Doing nothing."
      puts ""
      puts ""
      next
    end

    puts "Dropping database located at #{data_path}."
    File.delete(data_path)
  end

  desc "Creates the database file if it does not already exist"
  task :create do
    environment = ENV["APP_ENV"] || "development"
    data_path = "./db/data/#{environment}.db"

    if File.exist?(data_path)
      puts "Database already exists at #{data_path}. Doing nothing."
    else
      SQLite3::Database.new(data_path)
      puts "Database created at #{data_path}."
    end
  end

  desc "Ensures database has all of the database migrations executed"
  task :migrate do
    # TODO: implement
  end
end
