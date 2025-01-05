require "sqlite3"

namespace :db do
  desc "Removes the database file"
  task :drop do
    environment = ENV["APP_ENV"] || "development"
    data_path = "./db/data/#{environment}.db"
    execute_drop = ENV["CONFIRM"] == "true"

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
    environment = ENV["APP_ENV"] || "development"
    data_path = "./db/data/#{environment}.db"

    if File.exist?(data_path)
      db = SQLite3::Database.open(data_path)
      # NOTE: We want `.first.first` as the query result is `[[0]]`
      database_version = db.execute("PRAGMA user_version;").first.first

      Dir
        .glob("db/migrate/*")
        .map do |filepath|
          # Turn db/migration/0042_my_migration.rb into "0042"
          version = filepath.split("/").last.split(".").first.split("_").first

          # Don't attempt to migrate the migration template.
          next if version == "template"

          {version:, filepath:}
        end
        .compact
        .sort { |a, b| a[:version].to_i <=> b[:version].to_i }
        .each do |version_hash|
          version = version_hash[:version]
          filepath = version_hash[:filepath]

          if version.to_i <= database_version
            puts " >> Database already includes version #{version.to_i}."
            next
          end

          load filepath

          puts " >> Migrating database to version #{version.to_i}."

          Object.const_get("Migration#{version}").new.migrate(data_path)
        end
    else
      puts ""
      puts ""
      puts "  >> Database does not exist. Doing nothing."
      puts ""
      puts ""
    end
  end

  desc "Generates an empty database migration file in the appropriate location"
  task :generate_migration, [:name] do |t, args|
    name = args[:name].to_s

    if name.empty?
      puts ""
      puts ""
      puts "  >> Migration name not provided. Doing nothing."
      puts ""
      puts ""
      next
    end

    latest_version =
      Dir
        .glob("db/migrate/*")
        .map do |filepath|
          # Turn db/migration/0042_my_migration.rb into 0042
          version = filepath.split("/").last.split(".").first.split("_").first
          next nil if version == "template"
          version
        end
        .compact
        .last
        .to_i

    version = (latest_version + 1).to_s.rjust(4, "0")
    filepath = "db/migrate/#{version}_#{name}.rb"

    puts " /------------------------------------------------------------------\\"
    puts " | -> Creating #{filepath}"
    puts " \\------------------------------------------------------------------/"
    puts ""

    migration_file_data =
      File
        .read("db/migrate/template.rb")
        .gsub("~~~VERSION~~~", version)

    File.write(filepath, migration_file_data)
  end
end
