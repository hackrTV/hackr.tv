namespace :import do
  desc "Import radio stations from YAML to database"
  task radio_stations: :environment do
    require "yaml"

    yaml_file = Rails.root.join("config", "radio_stations.yml")
    data = YAML.load_file(yaml_file)

    puts "Importing radio stations from #{yaml_file}..."

    data["stations"].each_with_index do |station_data, index|
      station = RadioStation.find_or_initialize_by(slug: station_data["slug"])
      station.assign_attributes(
        name: station_data["name"],
        description: station_data["description"],
        genre: station_data["genre"],
        color: station_data["color"],
        stream_url: station_data["stream_url"],
        position: index
      )

      if station.save
        puts "✓ Imported: #{station.name} (position: #{station.position})"
      else
        puts "✗ Failed to import #{station_data["name"]}: #{station.errors.full_messages.join(", ")}"
      end
    end

    puts "\nImport complete! #{RadioStation.count} radio stations in database."
  end
end
