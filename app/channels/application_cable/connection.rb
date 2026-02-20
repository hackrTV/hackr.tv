module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_hackr

    def connect
      self.current_hackr = find_hackr
    end

    private

    def find_hackr
      # Path 1: Cookie auth (existing)
      if (hackr = GridHackr.find_by(id: cookies.encrypted[:grid_hackr_id]))
        return hackr
      end

      # Path 2: Admin token auth via query params
      if request.params[:token].present? && request.params[:hackr_alias].present?
        return find_hackr_by_admin_token
      end

      nil # anonymous
    end

    def find_hackr_by_admin_token
      token = request.params[:token]
      hackr_alias = request.params[:hackr_alias]

      reject_unauthorized_connection unless token.is_a?(String)

      hackr = GridHackr.authenticate_by_token(hackr_alias, token)
      unless hackr
        Rails.logger.warn("[ActionCable] Invalid token from #{request.remote_ip} for alias '#{hackr_alias}'")
        reject_unauthorized_connection
      end

      unless hackr.admin?
        Rails.logger.warn("[ActionCable] Token auth denied for non-admin '#{hackr_alias}'")
        reject_unauthorized_connection
      end

      Rails.logger.info("[ActionCable] Admin token auth: #{hackr.hackr_alias}")
      hackr
    end
  end
end
