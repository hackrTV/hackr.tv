namespace :api do
  desc "Generate API token for a hackr"
  task :generate_token, [:alias] => :environment do |t, args|
    hackr = GridHackr.find_by!(hackr_alias: args[:alias])
    hackr.generate_api_token!
    puts "API Token for #{hackr.hackr_alias}: #{hackr.api_token}"
  end
end
