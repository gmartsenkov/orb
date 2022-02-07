require "../spec_helper"

Spectator.describe Orb::Clauses::OrderBy do
  describe "#initialize" do
    context "with valid arguments" do
      it "can be initialized with asc" do
        expect(described_class.new([{"name", "asc"}]).columns).to eq([{"name", "asc"}])
      end

      it "can be initialized with desc" do
        expect(described_class.new([{"name", "desc"}]).columns).to eq([{"name", "desc"}])
      end
    end

    context "with invalid direction" do
      it "raises an exception" do
        expect { described_class.new([{"name", "invalid"}]) }.to raise_error("Invalid ORDER BY direction - invalid")
      end
    end
  end

  describe "#sql" do
    it "generates the correct sql" do
      expect(described_class.new([{"name", "desc"}, {"id", "asc"}]).to_sql(0)).to eq("ORDER BY name desc, id asc")
    end
  end
end
