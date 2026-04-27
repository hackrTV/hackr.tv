# frozen_string_literal: true

class Admin::GridTransactionsController < Admin::ApplicationController
  PER_PAGE = 100

  # GET /root/grid_transactions
  def index
    @transactions = GridTransaction
      .includes(from_cache: :grid_hackr, to_cache: :grid_hackr)
      .order(created_at: :desc, id: :desc)

    # Filter: tx_type
    if params[:tx_type].present? && GridTransaction::TX_TYPES.include?(params[:tx_type])
      @transactions = @transactions.by_type(params[:tx_type])
    end

    # Filter: hackr_alias → resolve to cache(s)
    if params[:hackr_alias].present?
      hackr = GridHackr.find_by("LOWER(hackr_alias) = ?", params[:hackr_alias].downcase)
      if hackr
        cache_ids = GridCache.where(grid_hackr: hackr).pluck(:id)
        @transactions = if cache_ids.any?
          @transactions.where(from_cache_id: cache_ids)
            .or(@transactions.where(to_cache_id: cache_ids))
        else
          @transactions.none
        end
      else
        @transactions = @transactions.none
        @hackr_not_found = true
      end
    end

    # Filter: date range
    if params[:date_from].present?
      begin
        @transactions = @transactions.where("grid_transactions.created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
      rescue ArgumentError
        # ignore malformed date
      end
    end

    if params[:date_to].present?
      begin
        @transactions = @transactions.where("grid_transactions.created_at <= ?", Date.parse(params[:date_to]).end_of_day)
      rescue ArgumentError
        # ignore malformed date
      end
    end

    # Filter: memo
    if params[:memo].present?
      escaped_memo = ActiveRecord::Base.sanitize_sql_like(params[:memo])
      @transactions = @transactions.where("memo LIKE ?", "%#{escaped_memo}%")
    end

    # Pagination
    @per_page = PER_PAGE
    @offset = [params[:offset].to_i, 0].max
    @total_count = @transactions.count
    @transactions = @transactions.offset(@offset).limit(@per_page)
  end

  private

  def format_cred(amount)
    prefix = amount.negative? ? "-" : ""
    "#{prefix}#{amount.abs.to_s.reverse.scan(/\d{1,3}/).join(",").reverse}"
  end
  helper_method :format_cred

  def cache_display(cache)
    if cache.system?
      "[#{cache.system_type.upcase}]"
    elsif cache.grid_hackr
      cache.grid_hackr.hackr_alias
    else
      cache.address
    end
  end
  helper_method :cache_display
end
