# frozen_string_literal: true

module Grid
  class DenService
    class DenAlreadyExists < StandardError; end
    class DenNotFound < StandardError; end
    class NotInDenOrCorridor < StandardError; end

    DEN_STORAGE_CAP = 16
    MAX_DEN_FIXTURES = 3
    RESIDENTIAL_CORRIDOR_SLUG = "residential-corridor"
    MAX_SLUG_RETRIES = 3

    def initialize(hackr)
      @hackr = hackr
    end

    # Creates den room + bidirectional exits in the Residential District.
    # Raises DenAlreadyExists if hackr already has a den.
    # Pass consume_item: to atomically destroy the chip in the same transaction.
    def create_den!(consume_item: nil)
      corridor = GridRoom.find_by!(slug: RESIDENTIAL_CORRIDOR_SLUG)

      retries = 0
      begin
        den_slug = generate_den_slug

        ActiveRecord::Base.transaction do
          # Lock hackr row to serialize concurrent create_den! attempts
          @hackr.lock!
          raise DenAlreadyExists, "You already have a den." if GridRoom.exists?(owner: @hackr)

          den = GridRoom.create!(
            name: "#{@hackr.hackr_alias}'s Den",
            slug: den_slug,
            description: "A private node in the Residential District. Sparse but functional.",
            room_type: "den",
            grid_zone: corridor.grid_zone,
            owner: @hackr,
            locked: false
          )

          # Corridor → Den (direction is den slug)
          GridExit.create!(
            from_room: corridor,
            to_room: den,
            direction: den_slug,
            locked: false
          )

          # Den → Corridor (always "out")
          GridExit.create!(
            from_room: den,
            to_room: corridor,
            direction: "out",
            locked: false
          )

          # Consume the chip atomically with den creation
          consume_item&.destroy!

          den
        end
      rescue ActiveRecord::RecordNotUnique => e
        retries += 1
        retry if retries < MAX_SLUG_RETRIES && e.message.include?("slug")
        raise DenAlreadyExists, "You already have a den." if e.message.include?("owner_id")
        raise
      end
    end

    def rename_den!(name)
      den = find_den!
      den.update!(name: name)
      den
    end

    def describe_den!(description)
      den = find_den!
      den.update!(description: description)
      den
    end

    def invite!(guest_alias)
      den = find_den!
      guest = GridHackr.find_by!("LOWER(hackr_alias) = ?", guest_alias.downcase)

      invite = GridDenInvite.find_or_initialize_by(
        hackr: @hackr, guest: guest, den: den
      )
      invite.assign_attributes(expires_at: 1.hour.from_now, revoked_at: nil)
      invite.save!
      invite
    rescue ActiveRecord::RecordNotUnique
      # Concurrent invite race — retry with fresh lookup
      invite = GridDenInvite.find_by!(hackr: @hackr, guest: guest, den: den)
      invite.update!(expires_at: 1.hour.from_now, revoked_at: nil)
      invite
    end

    def uninvite!(guest_alias)
      den = find_den!
      guest = GridHackr.find_by!("LOWER(hackr_alias) = ?", guest_alias.downcase)

      GridDenInvite.where(hackr: @hackr, guest: guest, den: den)
        .where(revoked_at: nil)
        .find_each(&:revoke!)
    end

    def lock_den!(from_room)
      den = find_den!
      raise NotInDenOrCorridor unless in_den_or_corridor?(from_room, den)
      den.update!(locked: true)
    end

    def unlock_den!(from_room)
      den = find_den!
      raise NotInDenOrCorridor unless in_den_or_corridor?(from_room, den)
      den.update!(locked: false)
    end

    # Access check: can this hackr enter a given den?
    def can_enter_den?(den)
      return true if den.owner_id == @hackr.id
      GridDenInvite.active.exists?(hackr_id: den.owner_id, guest: @hackr, den: den)
    end

    private

    def find_den!
      @den ||= GridRoom.find_by(owner: @hackr) || raise(DenNotFound, "You don't have a den.")
    end

    def in_den_or_corridor?(room, den)
      room.id == den.id || room.slug == RESIDENTIAL_CORRIDOR_SLUG
    end

    def generate_den_slug
      sanitized = @hackr.hackr_alias.downcase.gsub(/[^a-z0-9]/, "-").squeeze("-").gsub(/\A-|-\z/, "")
      "den-#{sanitized}-#{SecureRandom.hex(3)}"
    end
  end
end
