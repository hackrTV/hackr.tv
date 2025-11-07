module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_hackr

    def connect
      self.current_hackr = find_verified_hackr
    end

    private

    def find_verified_hackr
      if (verified_hackr = GridHackr.find_by(id: cookies.encrypted[:grid_hackr_id]))
        verified_hackr
      else
        reject_unauthorized_connection
      end
    end
  end
end
