require "./spec_helper"

Spectator.describe Orb::Relation do
  subject { Orb::ExampleRelation.new }

  describe "#table" do
    it "returns the correct table" do
      expect(Orb::ExampleRelation.table_name).to eq "users"
    end
  end

  describe "#column_names" do
    it "returns the correct columns" do
      expect(Orb::ExampleRelation.column_names).to eq ["id", "name", "email"]
    end
  end
end
