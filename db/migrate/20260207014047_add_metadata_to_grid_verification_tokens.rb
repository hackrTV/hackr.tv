class AddMetadataToGridVerificationTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_verification_tokens, :metadata, :json, default: {}
  end
end
