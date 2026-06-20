# frozen_string_literal: true

class AddBioToGridHackrs < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_hackrs, :bio, :text
  end
end
