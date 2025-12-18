# frozen_string_literal: true

# Controller for the terminal access credentials page
# Displays the daily rotating password for SSH access
class TerminalController < ApplicationController
  layout "terminal"

  def index
    require_relative "../../lib/terminal/password"

    @password = Terminal::Password.daily_password
    @next_rotation = Terminal::Password.next_rotation_at
    @countdown = Terminal::Password.rotation_countdown
    @ssh_command = "ssh access@terminal.hackr.tv -p 9915"
  end
end
