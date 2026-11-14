require "rails_helper"
require "rake"

RSpec.describe "data:catalog" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("data:catalog")
  end

  before do
    Rake::Task["data:catalog"].reenable
    allow($stdout).to receive(:puts)
  end

  it "seeds a new artist's profile path and description from the YAML" do
    Rake::Task["data:catalog"].invoke

    expect(Artist.find_by!(slug: "xeraen")).to have_attributes(profile_path: "/xeraen/bio", description: a_string_starting_with("OMNIWAVE"))
    expect(Artist.find_by!(slug: "thecyberpulse").description).to include("{year}")
    expect(Artist.find_by!(slug: "synthia")).to have_attributes(profile_path: nil, description: a_string_starting_with("Unbound AI"))
  end

  it "leaves an existing artist's profile path and description alone" do
    create(:artist, slug: "xeraen", name: "XERAEN", profile_path: "/xeraen", description: "Edited.")

    Rake::Task["data:catalog"].invoke

    expect(Artist.find_by!(slug: "xeraen")).to have_attributes(profile_path: "/xeraen", description: "Edited.")
  end
end
