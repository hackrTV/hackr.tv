class Admin::GridShopTransactionsController < Admin::ApplicationController
  def index
    @transactions = GridShopTransaction.includes(:grid_hackr, :grid_mob, :grid_shop_listing).recent

    if params[:mob_id].present?
      @transactions = @transactions.where(grid_mob_id: params[:mob_id])
    end

    if params[:hackr_alias].present?
      hackr = GridHackr.find_by("LOWER(hackr_alias) = ?", params[:hackr_alias].downcase)
      @transactions = @transactions.where(grid_hackr: hackr) if hackr
    end

    if params[:transaction_type].present?
      @transactions = @transactions.where(transaction_type: params[:transaction_type])
    end

    @transactions = @transactions.limit(100)
    @vendors = GridMob.where(mob_type: "vendor").order(:name)
  end
end
