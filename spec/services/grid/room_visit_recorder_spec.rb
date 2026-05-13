require "rails_helper"

RSpec.describe Grid::RoomVisitRecorder do
  let(:hackr) { create(:grid_hackr, :online) }
  let(:room) { hackr.current_room }

  describe ".record!" do
    it "creates a visit record" do
      expect { described_class.record!(hackr: hackr, room: room) }
        .to change(GridRoomVisit, :count).by(1)
    end

    it "is idempotent — second call does not create duplicate" do
      described_class.record!(hackr: hackr, room: room)
      expect { described_class.record!(hackr: hackr, room: room) }
        .not_to change(GridRoomVisit, :count)
    end

    it "sets first_visited_at" do
      described_class.record!(hackr: hackr, room: room)
      visit = GridRoomVisit.last
      expect(visit.first_visited_at).to be_within(2.seconds).of(Time.current)
    end

    it "does nothing with nil hackr" do
      expect { described_class.record!(hackr: nil, room: room) }
        .not_to change(GridRoomVisit, :count)
    end

    it "does nothing with nil room" do
      expect { described_class.record!(hackr: hackr, room: nil) }
        .not_to change(GridRoomVisit, :count)
    end
  end

  describe ".record_by_id!" do
    it "creates a visit record by room ID" do
      expect { described_class.record_by_id!(hackr: hackr, room_id: room.id) }
        .to change(GridRoomVisit, :count).by(1)
    end

    it "is idempotent" do
      described_class.record_by_id!(hackr: hackr, room_id: room.id)
      expect { described_class.record_by_id!(hackr: hackr, room_id: room.id) }
        .not_to change(GridRoomVisit, :count)
    end

    it "does nothing with nil room_id" do
      expect { described_class.record_by_id!(hackr: hackr, room_id: nil) }
        .not_to change(GridRoomVisit, :count)
    end
  end
end
