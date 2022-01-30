require "../spec_helper"

Spectator.describe "Postgres queries" do
  include Orb::Query::Helpers

  let(now) { Time.utc(2020, 1, 1) }

  describe "select" do
    before_each do
      Factory.build(Orb::ExampleRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::ExampleRelation.new(id: 2, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "returns the correct results" do
      results = Orb.query(Orb::Query.new.select(:id, :name).from(:users), Orb::ExampleRelation)
      expect(results.size).to eq 2

      one, two = results
      expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => nil, "created_at" => nil})
      expect(two.to_h).to eq({"id" => 2, "name" => "Mark", "email" => nil, "created_at" => nil})
    end

    context "with a relation" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::ExampleRelation), Orb::ExampleRelation)
        expect(results.size).to eq 2

        one, two = results
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
        expect(two.to_h).to eq({"id" => 2, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
      end
    end
  end

  describe "distinct" do
    before_each do
      Factory.build(Orb::ExampleRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::ExampleRelation.new(id: 2, name: "Mark", email: "mark@snow", created_at: now))
      Factory.build(Orb::ExampleRelation.new(id: 3, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "returns the correct results" do
      results = Orb.query(Orb::Query.new.distinct(:name).from(:users), Orb::ExampleRelation)
      expect(results.size).to eq 2

      one, two = results
      expect(one.to_h).to eq({"id" => nil, "name" => "Mark", "email" => nil, "created_at" => nil})
      expect(two.to_h).to eq({"id" => nil, "name" => "Jon", "email" => nil, "created_at" => nil})
    end

    context "with select and distinct" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::ExampleRelation).distinct(:name), Orb::ExampleRelation)
        expect(results.size).to eq 2

        one, two = results
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
        expect(two.to_h).to eq({"id" => 2, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
      end
    end
  end

  describe "where" do
    before_each do
      Factory.build(Orb::ExampleRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::ExampleRelation.new(id: 2, name: "Bob", email: "bob@snow", created_at: now))
      Factory.build(Orb::ExampleRelation.new(id: 3, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "returns the correct results" do
      results = Orb.query(Orb::Query.new.select(Orb::ExampleRelation).where(name: "Jon"), Orb::ExampleRelation)
      expect(results.size).to eq 1
      one = results.first
      expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
    end

    context "with operator" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::ExampleRelation).where(:id, :>=, 2), Orb::ExampleRelation)
        expect(results.size).to eq 2
        one, two = results
        expect(one.to_h).to eq({"id" => 2, "name" => "Bob", "email" => "bob@snow", "created_at" => now})
        expect(two.to_h).to eq({"id" => 3, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
      end
    end

    context "with fragment" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::ExampleRelation).where(fragment("LOWER(name) = ?", ["jon"])), Orb::ExampleRelation)
        expect(results.size).to eq 1
        one = results.first
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
      end
    end
  end

  describe "limit and offset" do
    before_each do
      Factory.build(Orb::ExampleRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::ExampleRelation.new(id: 2, name: "Bob", email: "bob@snow", created_at: now))
      Factory.build(Orb::ExampleRelation.new(id: 3, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "limits the results" do
      results = Orb.query(Orb::Query.new.select(Orb::ExampleRelation).limit(1), Orb::ExampleRelation)
      expect(results.size).to eq 1
      one = results.first
      expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
    end

    it "applies an offset" do
      results = Orb.query(Orb::Query.new.select(Orb::ExampleRelation).offset(1), Orb::ExampleRelation)
      expect(results.size).to eq 2
      one, two = results
      expect(one.to_h).to eq({"id" => 2, "name" => "Bob", "email" => "bob@snow", "created_at" => now})
      expect(two.to_h).to eq({"id" => 3, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
    end

    it "limits and offsets the query" do
      results = Orb.query(Orb::Query.new.select(Orb::ExampleRelation).offset(1).limit(1), Orb::ExampleRelation)
      expect(results.size).to eq 1
      one = results.first
      expect(one.to_h).to eq({"id" => 2, "name" => "Bob", "email" => "bob@snow", "created_at" => now})
    end
  end
end
