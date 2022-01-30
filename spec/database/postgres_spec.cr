require "../spec_helper"

Spectator.describe "Postgres queries" do
  include Orb::Query::Helpers

  let(now) { Time.utc(2020, 1, 1) }

  describe "select" do
    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "returns the correct results" do
      results = Orb.query(Orb::Query.new.select(:id, :name).from(:users), Orb::UserRelation)
      expect(results.size).to eq 2

      one, two = results
      expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => nil, "created_at" => nil})
      expect(two.to_h).to eq({"id" => 2, "name" => "Mark", "email" => nil, "created_at" => nil})
    end

    context "with a relation" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::UserRelation), Orb::UserRelation)
        expect(results.size).to eq 2

        one, two = results
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
        expect(two.to_h).to eq({"id" => 2, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
      end
    end
  end

  describe "distinct" do
    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "Mark", email: "mark@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 3, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "returns the correct results" do
      results = Orb.query(Orb::Query.new.distinct(:name).from(:users), Orb::UserRelation)
      expect(results.size).to eq 2

      one, two = results
      expect(one.to_h).to eq({"id" => nil, "name" => "Mark", "email" => nil, "created_at" => nil})
      expect(two.to_h).to eq({"id" => nil, "name" => "Jon", "email" => nil, "created_at" => nil})
    end

    context "with select and distinct" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::UserRelation).distinct(:name), Orb::UserRelation)
        expect(results.size).to eq 2

        one, two = results
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
        expect(two.to_h).to eq({"id" => 2, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
      end
    end
  end

  describe "where" do
    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "Bob", email: "bob@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 3, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "returns the correct results" do
      results = Orb.query(Orb::Query.new.select(Orb::UserRelation).where(name: "Jon"), Orb::UserRelation)
      expect(results.size).to eq 1
      one = results.first
      expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
    end

    context "with operator" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::UserRelation).where(:id, :>=, 2), Orb::UserRelation)
        expect(results.size).to eq 2
        one, two = results
        expect(one.to_h).to eq({"id" => 2, "name" => "Bob", "email" => "bob@snow", "created_at" => now})
        expect(two.to_h).to eq({"id" => 3, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
      end
    end

    context "with fragment" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::UserRelation).where(fragment("LOWER(name) = ?", ["jon"])), Orb::UserRelation)
        expect(results.size).to eq 1
        one = results.first
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
      end
    end

    context "when or" do
      it "returns the correct results" do
        results = Orb.query(Orb::Query.new.select(Orb::UserRelation).where(:id, :>=, 3).or_where(id: 1), Orb::UserRelation)
        expect(results.size).to eq 2
        one, two = results
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
        expect(two.to_h).to eq({"id" => 3, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
      end
    end
  end

  describe "limit and offset" do
    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "Bob", email: "bob@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 3, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "limits the results" do
      results = Orb.query(Orb::Query.new.select(Orb::UserRelation).limit(1), Orb::UserRelation)
      expect(results.size).to eq 1
      one = results.first
      expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
    end

    it "applies an offset" do
      results = Orb.query(Orb::Query.new.select(Orb::UserRelation).offset(1), Orb::UserRelation)
      expect(results.size).to eq 2
      one, two = results
      expect(one.to_h).to eq({"id" => 2, "name" => "Bob", "email" => "bob@snow", "created_at" => now})
      expect(two.to_h).to eq({"id" => 3, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
    end

    it "limits and offsets the query" do
      results = Orb.query(Orb::Query.new.select(Orb::UserRelation).offset(1).limit(1), Orb::UserRelation)
      expect(results.size).to eq 1
      one = results.first
      expect(one.to_h).to eq({"id" => 2, "name" => "Bob", "email" => "bob@snow", "created_at" => now})
    end
  end

  context "join" do
    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "Bob", email: "bob@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 3, name: "Mark", email: "mark@snow", created_at: now))

      Orb.exec(Orb::Query.new.insert(:user_avatar, {user_id: 1, avatar_url: "jon.png"}))
      Orb.exec(Orb::Query.new.insert(:user_avatar, {user_id: 2, avatar_url: "bob.jpg"}))
    end

    context "inner join" do
      it "returns the correc users" do
        results = Orb.query(Orb::Query.new.select(Orb::UserRelation).join(:user_avatar, {"users.id", "user_id"}), Orb::UserRelation)
        expect(results.size).to eq 2
        one, two = results
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
        expect(two.to_h).to eq({"id" => 2, "name" => "Bob", "email" => "bob@snow", "created_at" => now})
      end
    end

    context "left join" do
      it "returns the correc users" do
        results = Orb.query(
          Orb::Query
            .new
            .select(Orb::UserRelation)
            .join(:user_avatar, {"users.id", "user_id"})
            .where("user_avatar.avatar_url", :LIKE, "%png%"),
          Orb::UserRelation
        )

        expect(results.size).to eq 1
        one = results.first
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
      end
    end
  end

  context "update" do
    let(update) do
      Orb.exec(Orb::Query.new.update(:users, {name: "Jon 2", email: "jon2@snow"}).where(id: 1))
    end

    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "Bob", email: "bob@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 3, name: "Mark", email: "mark@snow", created_at: now))
    end

    it "update the correct record" do
      expect { update }.to change {
        Orb.query(Orb::Query.new.select(Orb::UserRelation).where(:id, 1), Orb::UserRelation).map(&.to_h)
      }.from([{"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now}])
        .to([{"id" => 1, "name" => "Jon 2", "email" => "jon2@snow", "created_at" => now}])
    end

    it "does not update the other records" do
      expect { update }.not_to change {
        Orb.query(Orb::Query.new.select(Orb::UserRelation).where(:id, :!=, 1), Orb::UserRelation).map(&.to_h)
      }
    end
  end
end
