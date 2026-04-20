# frozen_string_literal: true

module Grid
  module InventoryErrors
    class InventoryFull < StandardError; end
    class StackLimitExceeded < StandardError; end
  end
end
