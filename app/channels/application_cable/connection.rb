module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_hackr

    def connect
      self.current_hackr = find_hackr
    end

    private

    def find_hackr
      # Allow anonymous connections (return nil if not logged in)
      GridHackr.find_by(id: cookies.encrypted[:grid_hackr_id])
    end
  end
end
