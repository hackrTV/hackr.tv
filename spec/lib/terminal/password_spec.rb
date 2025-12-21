# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terminal::Password do
  describe ".daily_password" do
    it "returns a three-word password" do
      password = described_class.daily_password

      expect(password).to match(/\A\w+-\w+-\w+\z/)
    end

    it "uses words from the word list" do
      password = described_class.daily_password
      words = password.split("-")

      words.each do |word|
        expect(Terminal::Password::WORD_LIST).to include(word)
      end
    end

    it "is deterministic for the same day" do
      password1 = described_class.daily_password
      password2 = described_class.daily_password

      expect(password1).to eq(password2)
    end
  end

  describe ".generate_password_for_date" do
    it "generates different passwords for different dates" do
      # Use Date.today to match the implementation
      today = Date.today
      tomorrow = Date.today + 1
      yesterday = Date.today - 1

      password_today = described_class.generate_password_for_date(today)
      password_tomorrow = described_class.generate_password_for_date(tomorrow)
      password_yesterday = described_class.generate_password_for_date(yesterday)

      expect(password_today).not_to eq(password_tomorrow)
      expect(password_today).not_to eq(password_yesterday)
      expect(password_tomorrow).not_to eq(password_yesterday)
    end

    it "generates the same password for the same date" do
      date = Date.new(2125, 9, 9)  # Fracture Day reference

      password1 = described_class.generate_password_for_date(date)
      password2 = described_class.generate_password_for_date(date)

      expect(password1).to eq(password2)
    end

    it "returns a three-word password" do
      date = Date.new(2125, 1, 1)
      password = described_class.generate_password_for_date(date)

      expect(password.split("-").length).to eq(3)
    end
  end

  describe ".valid?" do
    it "returns true for today's password" do
      password = described_class.daily_password

      expect(described_class.valid?(password)).to be true
    end

    it "returns true for case-insensitive match" do
      password = described_class.daily_password

      expect(described_class.valid?(password.upcase)).to be true
      expect(described_class.valid?(password.downcase)).to be true
    end

    it "returns true when password has leading/trailing whitespace" do
      password = described_class.daily_password

      expect(described_class.valid?("  #{password}  ")).to be true
    end

    it "returns false for nil" do
      expect(described_class.valid?(nil)).to be false
    end

    it "returns false for empty string" do
      expect(described_class.valid?("")).to be false
    end

    it "returns false for incorrect password" do
      expect(described_class.valid?("wrong-password-here")).to be false
    end

    it "returns false for yesterday's password" do
      # Use Date.today to match the implementation (which uses Date.today for
      # compatibility with standalone PAM scripts that don't load ActiveSupport)
      yesterday = Date.today - 1
      old_password = described_class.generate_password_for_date(yesterday)

      expect(described_class.valid?(old_password)).to be false
    end
  end

  describe ".time_until_rotation" do
    it "returns a positive duration" do
      duration = described_class.time_until_rotation

      expect(duration).to be > 0
    end

    it "is less than 24 hours" do
      duration = described_class.time_until_rotation

      expect(duration).to be < 24.hours
    end
  end

  describe ".rotation_countdown" do
    it "returns a formatted HH:MM:SS string" do
      countdown = described_class.rotation_countdown

      expect(countdown).to match(/\A\d{2}:\d{2}:\d{2}\z/)
    end

    it "has valid hour values (00-23)" do
      countdown = described_class.rotation_countdown
      hours = countdown.split(":").first.to_i

      expect(hours).to be >= 0
      expect(hours).to be < 24
    end

    it "has valid minute values (00-59)" do
      countdown = described_class.rotation_countdown
      minutes = countdown.split(":")[1].to_i

      expect(minutes).to be >= 0
      expect(minutes).to be < 60
    end

    it "has valid second values (00-59)" do
      countdown = described_class.rotation_countdown
      seconds = countdown.split(":").last.to_i

      expect(seconds).to be >= 0
      expect(seconds).to be < 60
    end
  end

  describe ".next_rotation_at" do
    it "returns tomorrow's beginning of day" do
      expected = Date.tomorrow.beginning_of_day
      result = described_class.next_rotation_at

      expect(result).to eq(expected)
    end

    it "is in the future" do
      result = described_class.next_rotation_at

      expect(result).to be > Time.current
    end
  end

  describe "WORD_LIST" do
    it "contains only lowercase words" do
      Terminal::Password::WORD_LIST.each do |word|
        expect(word).to eq(word.downcase)
      end
    end

    it "has no duplicates" do
      expect(Terminal::Password::WORD_LIST.uniq.length).to eq(Terminal::Password::WORD_LIST.length)
    end

    it "has enough words for variety" do
      # With 3-word passwords, we want at least 20 words for decent entropy
      expect(Terminal::Password::WORD_LIST.length).to be >= 20
    end
  end

  describe "SEED" do
    it "references Fracture Day" do
      expect(Terminal::Password::SEED).to include("fracture")
      expect(Terminal::Password::SEED).to include("9915")
    end
  end
end
