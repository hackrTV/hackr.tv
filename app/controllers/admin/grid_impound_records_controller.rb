# frozen_string_literal: true

class Admin::GridImpoundRecordsController < Admin::ApplicationController
  before_action :set_record, only: %i[force_recover force_forfeit]
  before_action :require_dev_tools, only: %i[force_recover force_forfeit]

  # GET /root/grid_impound_records
  def index
    @records = GridImpoundRecord
      .includes(:grid_hackr, :grid_hackr_breach, :impounded_items)
      .order(created_at: :desc)

    if params[:hackr_alias].present?
      hackr = GridHackr.find_by("LOWER(hackr_alias) = ?", params[:hackr_alias].downcase)
      @records = hackr ? @records.where(grid_hackr: hackr) : @records.none
      @hackr_not_found = hackr.nil?
    end

    if params[:status].present? && GridImpoundRecord::STATUSES.include?(params[:status])
      @records = @records.where(status: params[:status])
    end

    @records = @records.limit(200)
  end

  # POST /root/grid_impound_records/:id/force_recover
  def force_recover
    unless @record.impounded?
      set_flash_error("Record ##{@record.id} is not impounded (status: #{@record.status}).")
      return redirect_to admin_grid_impound_records_path
    end

    hackr = @record.grid_hackr
    items_count = 0
    resolved_concurrently = false

    ActiveRecord::Base.transaction do
      hackr.lock!
      @record.lock!

      unless @record.impounded?
        resolved_concurrently = true
        raise ActiveRecord::Rollback
      end

      items = @record.impounded_items.to_a
      items_count = items.size
      items.each { |item| item.update!(grid_impound_record_id: nil) }
      @record.update!(status: "recovered")
      hackr.reset_loadout_cache!
    end

    if resolved_concurrently
      set_flash_error("Record ##{@record.id} was resolved by a concurrent request.")
      return redirect_to admin_grid_impound_records_path
    end

    set_flash_success("Force-recovered impound ##{@record.id} for #{hackr.hackr_alias}. #{items_count} item(s) returned to inventory (no CRED charged).")
    redirect_to admin_grid_impound_records_path
  end

  # POST /root/grid_impound_records/:id/force_forfeit
  def force_forfeit
    unless @record.impounded?
      set_flash_error("Record ##{@record.id} is not impounded (status: #{@record.status}).")
      return redirect_to admin_grid_impound_records_path
    end

    hackr = @record.grid_hackr
    items_count = 0
    resolved_concurrently = false

    ActiveRecord::Base.transaction do
      hackr.lock!
      @record.lock!

      unless @record.impounded?
        resolved_concurrently = true
        raise ActiveRecord::Rollback
      end

      items_count = @record.impounded_items.count
      @record.impounded_items.destroy_all
      @record.update!(status: "forfeited")
    end

    if resolved_concurrently
      set_flash_error("Record ##{@record.id} was resolved by a concurrent request.")
      return redirect_to admin_grid_impound_records_path
    end

    set_flash_success("Force-forfeited impound ##{@record.id} for #{hackr.hackr_alias}. #{items_count} item(s) destroyed.")
    redirect_to admin_grid_impound_records_path
  end

  private

  def set_record
    @record = GridImpoundRecord.includes(:grid_hackr, :impounded_items).find(params[:id])
  end
end
