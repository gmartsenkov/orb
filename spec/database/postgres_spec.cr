require "../spec_helper"

Spectator.describe "Postgres queries" do
  describe "select" do
    let(now) { Time.local }

    before_each do
      Factory.build(Orb::ExampleRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::ExampleRelation.new(id: 2, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "returns the correct results" do
      results = Orb.query(Orb::Query.new.select(:id, :name).from(:users), Orb::ExampleRelation)
      expect(results.size).to eq 2

      one, two = results
      expect(one.id).to eq 1
      expect(one.name).to eq "Jon"
      expect(one.email).to eq nil
      expect(one.created_at).to eq nil
      expect(two.id).to eq 2
      expect(two.name).to eq "Mark"
      expect(two.email).to eq nil
      expect(two.created_at).to eq nil
    end

    context "with a relation" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::ExampleRelation), Orb::ExampleRelation)
        expect(results.size).to eq 2

        one, two = results
        expect(one.id).to eq 1
        expect(one.name).to eq "Jon"
        expect(one.email).to eq "jon@snow"
        expect(one.created_at).to eq now
        expect(two.id).to eq 2
        expect(two.name).to eq "Mark"
        expect(two.email).to eq "mark@snow"
        expect(two.created_at).to eq now
      end
    end
  end
end
