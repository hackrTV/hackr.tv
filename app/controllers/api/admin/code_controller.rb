module Api
  module Admin
    class CodeController < BaseController
      # POST /api/admin/code/sync
      def sync
        CodeSyncJob.perform_later

        render json: {success: true, message: "Code sync job enqueued"}
      end
    end
  end
end
