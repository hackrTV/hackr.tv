require "rails_helper"

RSpec.describe Uplink::Callsign do
  it "is deterministic per hackr id" do
    expect(described_class.token(42)).to eq(described_class.token(42))
    expect(described_class.label(42)).to eq(described_class.label(42))
  end

  it "formats as SIG-XXXXXX with six uppercase hex digits" do
    expect(described_class.label(42)).to match(/\ASIG-[0-9A-F]{6}\z/)
    expect(described_class.token(42)).to match(/\A[0-9A-F]{6}\z/)
  end

  it "differs between hackrs and does not embed the id" do
    tokens = (1..50).map { |id| described_class.token(id) }
    expect(tokens.uniq.size).to eq(50)
    expect(described_class.label(123456)).not_to include("123456")
  end
end
