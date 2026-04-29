# frozen_string_literal: true

class Admin::GridWorldExportController < Admin::ApplicationController
  # GET /root/grid_world_export — download world data as .tar.gz
  def download
    data = Grid::WorldExporter.new.to_tar_gz
    timestamp = Time.current.strftime("%Y%m%d-%H%M%S")

    send_data data,
      filename: "world-export-#{timestamp}.tar.gz",
      type: "application/gzip",
      disposition: "attachment"
  end
end
