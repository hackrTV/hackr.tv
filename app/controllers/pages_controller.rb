class PagesController < ApplicationController
  def index
    render "mobile/index" if mobile?
  end

  def xeraen
    render "mobile/xeraen" if mobile?
  end

  def xeraen_linkz
  end

  def sector_x
  end
end
