module Grid
  class CommandParser
    attr_reader :hackr, :input, :event

    def initialize(hackr, input)
      @hackr = hackr
      @input = input.to_s.strip
      @event = nil
    end

    def execute
      return {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", event: nil} if input.empty?

      # Split input but preserve case in arguments
      parts = input.split
      command = parts.first&.downcase
      args = parts[1..]

      result = case command
      when "look", "l"
        look_command
      when "go", "move"
        go_command(args.first)
      when "north", "n"
        go_command("north")
      when "south", "s"
        go_command("south")
      when "east", "e"
        go_command("east")
      when "west", "w"
        go_command("west")
      when "up", "u"
        go_command("up")
      when "down", "d"
        go_command("down")
      when "say"
        say_command(args.join(" "))
      when "inventory", "inv", "i"
        inventory_command
      when "take", "get"
        take_command(args.join(" "))
      when "drop"
        drop_command(args.join(" "))
      when "examine", "ex", "x"
        examine_command(args.join(" "))
      when "talk"
        talk_command(args.join(" "))
      when "ask"
        ask_command(args)
      when "help", "?"
        help_command
      when "who"
        who_command
      when "clear", "cls"
        clear_command
      else
        "<span style='color: #f87171;'>Unknown command: #{command}. Type 'help' for a list of commands.</span>"
      end

      # Normalize result to hash format
      result.is_a?(Hash) ? result : {output: result, event: nil}
    end

    private

    def look_command
      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere. This shouldn't happen!</span>" unless room

      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output << "<span style='color: #22d3ee; font-weight: bold;'>#{room.name.upcase}</span> <span style='color: #666;'>::</span> <span style='color: #fbbf24;'>#{room.grid_zone.name}</span>"
      output << "<span style='color: #9ca3af;'>[#{room.color_scheme}]</span>" if room.color_scheme
      output << ""
      output << "<span style='color: #d0d0d0;'>#{room.description}</span>" if room.description
      output << ""

      # Show exits
      exits = room.exits_from.includes(:to_room)
      if exits.any?
        exit_list = exits.map { |e| "<span style='color: #22d3ee;'>#{e.direction}</span> <span style='color: #9ca3af;'>(#{e.to_room.name})</span>" }.join(", ")
        output << "<span style='color: #fbbf24;'>Exits:</span> #{exit_list}"
      else
        output << "<span style='color: #fbbf24;'>Exits:</span> <span style='color: #6b7280;'>none</span>"
      end

      # Show items
      items = room.grid_items.in_room(room)
      if items.any?
        output << ""
        output << "<span style='color: #fbbf24;'>Items:</span> <span style='color: #34d399;'>#{items.map(&:name).join(", ")}</span>"
      end

      # Show Mobs
      mobs = room.grid_mobs
      if mobs.any?
        output << ""
        output << "<span style='color: #fbbf24;'>Mobs:</span> <span style='color: #c084fc;'>#{mobs.map(&:name).join(", ")}</span>"
      end

      # Show other hackrs
      other_hackrs = room.grid_hackrs.where.not(id: hackr.id)
      if other_hackrs.any?
        output << ""
        output << "<span style='color: #fbbf24;'>Hackrs:</span> <span style='color: #a78bfa;'>#{other_hackrs.map(&:hackr_alias).join(", ")}</span>"
      end

      output.join("\n")
    end

    def go_command(direction)
      return "<span style='color: #fbbf24;'>Go where? Specify a direction: north, south, east, west, up, down</span>" unless direction

      old_room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless old_room

      exit = old_room.exits_from.find_by(direction: direction)
      return "<span style='color: #f87171;'>You can't go #{direction} from here.</span>" unless exit

      if exit.locked
        return "<span style='color: #f87171;'>The exit is locked.</span>" unless exit.requires_item && hackr.grid_items.exists?(exit.requires_item_id)
      end

      new_room = exit.to_room
      hackr.update!(current_room: new_room)

      {
        output: look_command,
        event: {
          type: "movement",
          hackr_alias: hackr.hackr_alias,
          direction: direction,
          from_room_id: old_room.id,
          to_room_id: new_room.id
        }
      }
    end

    def say_command(message)
      return "<span style='color: #fbbf24;'>Say what?</span>" if message.empty?

      GridMessage.create!(
        grid_hackr: hackr,
        room: hackr.current_room,
        message_type: "say",
        content: message
      )

      {
        output: "<span style='color: #a78bfa;'>[#{hackr.hackr_alias}]</span>: #{message}",
        event: {
          type: "say",
          hackr_alias: hackr.hackr_alias,
          message: message,
          room_id: hackr.current_room&.id
        }
      }
    end

    def inventory_command
      items = hackr.grid_items
      if items.any?
        "<span style='color: #fbbf24;'>Inventory:</span>\n" + items.map { |item| "  - <span style='color: #34d399;'>#{item.name}</span>" }.join("\n")
      else
        "<span style='color: #9ca3af;'>Your inventory is empty.</span>"
      end
    end

    def take_command(item_name)
      return "<span style='color: #fbbf24;'>Take what?</span>" if item_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      item = room.grid_items.in_room(room).find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{item_name}' here.</span>" unless item

      item.update!(grid_hackr: hackr, room: nil)

      {
        output: "<span style='color: #34d399;'>You take the #{item.name}.</span>",
        event: {
          type: "take",
          hackr_alias: hackr.hackr_alias,
          item_name: item.name,
          room_id: room.id
        }
      }
    end

    def drop_command(item_name)
      return "<span style='color: #fbbf24;'>Drop what?</span>" if item_name.empty?

      item = hackr.grid_items.find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{item_name}'.</span>" unless item

      room = hackr.current_room
      item.update!(room: room, grid_hackr: nil)

      {
        output: "<span style='color: #34d399;'>You drop the #{item.name}.</span>",
        event: {
          type: "drop",
          hackr_alias: hackr.hackr_alias,
          item_name: item.name,
          room_id: room.id
        }
      }
    end

    def examine_command(target)
      return "<span style='color: #fbbf24;'>Examine what?</span>" if target.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      # Check items in room
      item = room.grid_items.in_room(room).find_by("LOWER(name) = ?", target.downcase)
      return "<span style='color: #d0d0d0;'>#{item.description}</span>" if item

      # Check items in inventory
      item = hackr.grid_items.find_by("LOWER(name) = ?", target.downcase)
      return "<span style='color: #d0d0d0;'>#{item.description}</span>" if item

      # Check Mobs
      mob = room.grid_mobs.find_by("LOWER(name) = ?", target.downcase)
      return "<span style='color: #d0d0d0;'>#{mob.description}</span>" if mob

      "<span style='color: #f87171;'>You don't see '#{target}' here.</span>"
    end

    def talk_command(npc_name)
      # Handle "talk to <npc>" syntax
      npc_name = npc_name.sub(/^to\s+/, "")
      return "<span style='color: #fbbf24;'>Talk to whom?</span>" if npc_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      mob = room.grid_mobs.find_by("LOWER(name) = ?", npc_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{npc_name}' here.</span>" unless mob
      return "<span style='color: #9ca3af;'>#{mob.name} doesn't seem interested in talking.</span>" if mob.dialogue_tree.blank?

      dialogue = mob.dialogue_tree
      content = []
      content << "<span style='color: #c084fc;'>#{mob.name}</span>: <span style='color: #60a5fa;'>\"#{dialogue["greeting"]}\"</span>"

      if dialogue["topics"].present? && dialogue["topics"].any?
        content << ""
        content << "<span style='color: #9ca3af;'>You can ask about:</span> <span style='color: #fbbf24;'>#{dialogue["topics"].keys.join(", ")}</span>"
      end

      dialogue_box(content.join("\n"))
    end

    def ask_command(args)
      # Parse "ask <npc> about <topic>"
      return "<span style='color: #fbbf24;'>Ask whom about what? Usage: ask &lt;npc&gt; about &lt;topic&gt;</span>" if args.length < 3

      # Handle both "ask Synthia about mission" and "ask <npc> <topic>" formats
      about_index = args.index { |word| word.downcase == "about" }

      if about_index
        npc_name = args[0...about_index].join(" ")
        topic = args[(about_index + 1)..]&.join(" ")
      else
        npc_name = args.first
        topic = args[1..].join(" ")
      end

      return "<span style='color: #fbbf24;'>Ask whom about what?</span>" if npc_name.blank? || topic.blank?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      mob = room.grid_mobs.find_by("LOWER(name) = ?", npc_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{npc_name}' here.</span>" unless mob
      return "<span style='color: #9ca3af;'>#{mob.name} doesn't seem interested in talking.</span>" if mob.dialogue_tree.blank?

      dialogue = mob.dialogue_tree
      topics = dialogue["topics"] || {}

      # Try exact match first, then case-insensitive match
      response = topics[topic] || topics[topic.downcase] || topics.find { |k, v| k.downcase == topic.downcase }&.last

      if response
        content = "<span style='color: #c084fc;'>#{mob.name}</span>: <span style='color: #60a5fa;'>\"#{response}\"</span>"
      else
        available = topics.keys.join(", ")
        content = "<span style='color: #c084fc;'>#{mob.name}</span> doesn't know about '#{topic}'. <span style='color: #9ca3af;'>Try asking about:</span> <span style='color: #fbbf24;'>#{available}</span>"
      end
      dialogue_box(content)
    end

    def help_command
      <<~HELP
        <span style='color: #22d3ee; font-weight: bold;'>Available Commands:</span>

        <span style='color: #fbbf24;'>Navigation:</span>
          <span style='color: #34d399;'>look, l</span>                 - Look around the room
          <span style='color: #34d399;'>go &lt;direction&gt;</span>          - Move in a direction
          <span style='color: #34d399;'>north, n / south, s</span>     - Move north/south
          <span style='color: #34d399;'>east, e / west, w</span>       - Move east/west
          <span style='color: #34d399;'>up, u / down, d</span>         - Move up/down

        <span style='color: #fbbf24;'>Items:</span>
          <span style='color: #34d399;'>inventory, inv, i</span>       - View your inventory
          <span style='color: #34d399;'>take &lt;item&gt;</span>             - Pick up an item
          <span style='color: #34d399;'>drop &lt;item&gt;</span>             - Drop an item
          <span style='color: #34d399;'>examine &lt;target&gt;, x</span>     - Examine an item or NPC

        <span style='color: #fbbf24;'>NPCs:</span>
          <span style='color: #34d399;'>talk &lt;npc&gt;</span>              - Talk to an NPC
          <span style='color: #34d399;'>ask &lt;npc&gt; about &lt;topic&gt;</span> - Ask an NPC about a topic

        <span style='color: #fbbf24;'>Social:</span>
          <span style='color: #34d399;'>say &lt;message&gt;</span>           - Say something in the room
          <span style='color: #34d399;'>who</span>                     - See who's online

        <span style='color: #fbbf24;'>Utility:</span>
          <span style='color: #34d399;'>clear, cls</span>              - Clear the screen
          <span style='color: #34d399;'>help, ?</span>                 - Show this help message
      HELP
    end

    def who_command
      online = GridHackr.where.not(current_room: nil).order(:hackr_alias)
      if online.any?
        "<span style='color: #fbbf24;'>Online Hackrs:</span>\n" + online.map { |h| "  - <span style='color: #a78bfa;'>#{h.hackr_alias}</span> <span style='color: #9ca3af;'>(#{h.current_room&.name || "nowhere"})</span>" }.join("\n")
      else
        "<span style='color: #9ca3af;'>No hackrs are currently online.</span>"
      end
    end

    def clear_command
      {
        output: "",
        event: {type: "clear"}
      }
    end

    def dialogue_box(content)
      # Create a thin-bordered box around dialogue content
      # Add blank line before box, strip content to avoid blank lines inside
      "\n<div style='border: 1px solid #666; padding: 10px; margin: 5px 0; background: #0d0d0d;'>#{content.strip}</div>"
    end
  end
end
