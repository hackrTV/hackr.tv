require "rails_helper"

RSpec.describe GridRoomVisit, type: :model do
  let(:hackr) { create(:grid_hackr, :online) }
  let(:room) { hackr.current_room }

  it "creates a valid visit" do
    visit = described_class.create!(grid_hackr: hackr, grid_room: room, first_visited_at: Time.current)
    expect(visit).to be_persisted
  end

  it "enforces uniqueness on hackr + room" do
    described_class.create!(grid_hackr: hackr, grid_room: room, first_visited_at: Time.current)
    duplicate = described_class.new(grid_hackr: hackr, grid_room: room, first_visited_at: Time.current)
    expect(duplicate).not_to be_valid
  end

  it "allows same room for different hackrs" do
    hackr2 = create(:grid_hackr, current_room: room)
    described_class.create!(grid_hackr: hackr, grid_room: room, first_visited_at: Time.current)
    visit2 = described_class.create!(grid_hackr: hackr2, grid_room: room, first_visited_at: Time.current)
    expect(visit2).to be_persisted
  end

  it "cascades on hackr deletion" do
    described_class.create!(grid_hackr: hackr, grid_room: room, first_visited_at: Time.current)
    expect { hackr.destroy }.to change(described_class, :count).by(-1)
  end

  it "cascades on room deletion" do
    room2 = create(:grid_room, grid_zone: room.grid_zone)
    hackr.update!(current_room: room2)
    described_class.create!(grid_hackr: hackr, grid_room: room, first_visited_at: Time.current)
    expect { room.destroy }.to change(described_class, :count).by(-1)
  end
end
