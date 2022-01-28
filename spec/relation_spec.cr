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
      expect(Orb::ExampleRelation.column_names).to eq ["id", "name", "email", "created_at"]
    end
  end

  describe "#to_h" do
    let(now) { Time.local(2020, 1, 1, 1) }

    it "returns the object as a hash" do
      expect(Orb::ExampleRelation.new(id: 1, name: "bob", email: "jon@snow", created_at: now).to_h)
        .to eq({"id" => 1, "name" => "bob", "email" => "jon@snow", "created_at" => now})
    end
  end
end
