class AddContentTypeAndFeedSourceToOverlayTickers < ActiveRecord::Migration[8.0]
  def change
    add_column :overlay_tickers, :content_type, :string, default: "static", null: false
    add_column :overlay_tickers, :feed_source, :string
  end
end
