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
      results = Orb::UserRelation.query.select(:id, :name).from(:users).to_a
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

    context "it works for another relation" do
      before_each do
        Orb.exec(Orb::Query.new.insert(:user_avatar, {user_id: 1, avatar_url: "jon.png"}))
        Orb.exec(Orb::Query.new.insert(:user_avatar, {user_id: 2, avatar_url: "bob.jpg"}))
      end

      it "returns the correct avatars" do
        results = Orb::AvatarsRelation.query.to_a
        expect(results.size).to eq 2

        one, two = results
        expect(one.to_h.select("avatar_url", "user_id")).to eq({"avatar_url" => "jon.png", "user_id" => 1})
        expect(two.to_h.select("avatar_url", "user_id")).to eq({"avatar_url" => "bob.jpg", "user_id" => 2})
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
      results = Orb::UserRelation.query.where(name: "Jon").to_a
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
        results = Orb::UserRelation.query.where(fragment("LOWER(name) = ?", ["jon"])).to_a
        expect(results.size).to eq 1
        one = results.first
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
      end
    end

    context "when or" do
      it "returns the correct results" do
        results = Orb::UserRelation.query.where(:id, :>=, 3).or_where(id: 1).to_a
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
      results = Orb::UserRelation.query.limit(1).to_a
      expect(results.size).to eq 1
      one = results.first
      expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
    end

    it "applies an offset" do
      results = Orb::UserRelation.query.offset(1).to_a
      expect(results.size).to eq 2
      one, two = results
      expect(one.to_h).to eq({"id" => 2, "name" => "Bob", "email" => "bob@snow", "created_at" => now})
      expect(two.to_h).to eq({"id" => 3, "name" => "Mark", "email" => "mark@snow", "created_at" => now})
    end

    it "limits and offsets the query" do
      results = Orb::UserRelation.query.offset(1).limit(1).to_a
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
        results = Orb::UserRelation.query.join(:user_avatar, {"users.id", "user_id"}).to_a
        expect(results.size).to eq 2
        one, two = results
        expect(one.to_h).to eq({"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now})
        expect(two.to_h).to eq({"id" => 2, "name" => "Bob", "email" => "bob@snow", "created_at" => now})
      end
    end

    context "left join" do
      it "returns the correc users" do
        results = Orb::UserRelation
          .query
          .join(:user_avatar, {"users.id", "user_id"})
          .where("user_avatar.avatar_url", :LIKE, "%png%")
          .to_a

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

  context "insert" do
    let(create) do
      Orb.exec(Orb::Query.new.insert(:users, {id: 1, name: "Jon", email: "jon@snow", created_at: now}))
    end

    it "creates a record in the database" do
      expect { create }.to change {
        Orb.query(Orb::Query.new.select(Orb::UserRelation), Orb::UserRelation).map(&.to_h)
      }.from([] of Hash(String | Symbol, Orb::TYPES))
        .to([{"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now}])
    end

    context "when a relation" do
      let(create) do
        Orb.exec(Orb::Query.new.insert(Orb::UserRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now)))
      end

      it "creates a record in the database" do
        expect { create }.to change {
          Orb.query(Orb::Query.new.select(Orb::UserRelation), Orb::UserRelation).map(&.to_h)
        }.from([] of Hash(String | Symbol, Orb::TYPES))
          .to([{"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now}])
      end
    end
  end

  context "multi_insert" do
    let(create) do
      Orb.exec(
        Orb::Query.new.multi_insert(
          :users,
          [{id: 1, name: "Jon", email: "jon@snow", created_at: now}, {id: 2, name: "Mark", email: "mark@snow", created_at: now}]
        )
      )
    end

    it "creates a record in the database" do
      expect { create }.to change {
        Orb.query(Orb::Query.new.select(Orb::UserRelation), Orb::UserRelation).map(&.to_h)
      }.from([] of Hash(String | Symbol, Orb::TYPES))
        .to([
          {"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now},
          {"id" => 2, "name" => "Mark", "email" => "mark@snow", "created_at" => now},
        ])
    end

    context "with relation" do
      let(create) do
        Orb.exec(
          Orb::Query.new.multi_insert(
            [
              Orb::UserRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now),
              Orb::UserRelation.new(id: 2, name: "Mark", email: "mark@snow", created_at: now),
            ]
          )
        )
      end

      it "creates a record in the database" do
        expect { create }.to change {
          Orb.query(Orb::Query.new.select(Orb::UserRelation), Orb::UserRelation).map(&.to_h)
        }.from([] of Hash(String | Symbol, Orb::TYPES))
          .to([
            {"id" => 1, "name" => "Jon", "email" => "jon@snow", "created_at" => now},
            {"id" => 2, "name" => "Mark", "email" => "mark@snow", "created_at" => now},
          ])
      end
    end
  end

  describe "order by" do
    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Z", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "C", email: "mark@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 3, name: "A", email: "bob@snow", created_at: now))
    end

    it "returns the results ordered correctly" do
      results = Orb::UserRelation.query.order_by(:name).to_a
      expect(results.size).to eq 3

      one, two, three = results
      expect(one.to_h).to eq({"id" => 3, "name" => "A", "email" => "bob@snow", "created_at" => now})
      expect(two.to_h).to eq({"id" => 2, "name" => "C", "email" => "mark@snow", "created_at" => now})
      expect(three.to_h).to eq({"id" => 1, "name" => "Z", "email" => "jon@snow", "created_at" => now})
    end

    context "with multiple" do
      before_each do
        Factory.build(Orb::UserRelation.new(id: 4, name: "A", email: "arya@stark", created_at: now))
      end

      it "returns the results ordered correctly" do
        results = Orb::UserRelation.query.order_by([{"name", "asc"}, {"id", "desc"}]).to_a
        expect(results.size).to eq 4

        one, two, three, four = results
        expect(one.to_h).to eq({"id" => 4, "name" => "A", "email" => "arya@stark", "created_at" => now})
        expect(two.to_h).to eq({"id" => 3, "name" => "A", "email" => "bob@snow", "created_at" => now})
        expect(three.to_h).to eq({"id" => 2, "name" => "C", "email" => "mark@snow", "created_at" => now})
        expect(four.to_h).to eq({"id" => 1, "name" => "Z", "email" => "jon@snow", "created_at" => now})
      end
    end
  end

  describe "count" do
    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Z", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "C", email: "mark@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 3, name: "A", email: "bob@snow", created_at: now))
    end

    it "returns the correct number of records" do
      expect(Orb::UserRelation.query.count).to eq 3
    end

    context "it works with filters" do
      it "returns the correct count" do
        expect(Orb::UserRelation.query.where(fragment("name in ('A', 'C')")).count).to eq 2
      end
    end
  end

  describe "delete" do
    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Z", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "C", email: "mark@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 3, name: "A", email: "bob@snow", created_at: now))
    end

    it "deletes all of the users" do
      expect { Orb::UserRelation.query.delete(:users).commit }.to change { Orb::UserRelation.query.count }.from(3).to(0)
    end

    it "deletes with a condition" do
      expect { Orb::UserRelation.query.delete(:users).where(id: [1, 2]).commit }.to change { Orb::UserRelation.query.count }.from(3).to(1)
    end
  end

  describe "#combine" do
    before_each do
      Factory.build(Orb::UserRelation.new(id: 1, name: "Jon", email: "jon@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 2, name: "Bob", email: "bob@snow", created_at: now))
      Factory.build(Orb::UserRelation.new(id: 3, name: "Mark", email: "mark@snow", created_at: now))

      Orb.exec(Orb::Query.new.insert(:user_avatar, {id: 100, user_id: 1, avatar_url: "jon.png"}))
      Orb.exec(Orb::Query.new.insert(:user_avatar, {id: 101, user_id: 2, avatar_url: "bob.jpg"}))
    end

    it "combines the avatars" do
      results = Orb::UserRelation.query.to_a.as(Array(Orb::UserRelation))
      Orb::UserRelation.combine(results, "avatar")
      expect(results.size).to eq 3
      expect(results).to all be_a(Orb::UserRelation)
      one, two, three = results
      expect(one.id).to eq(1)
      expect(one.name).to eq("Jon")
      expect(one.avatar).to be_a(Orb::AvatarsRelation)
      expect(one.avatar.not_nil!.id).to eq(100)
      expect(one.avatar.not_nil!.user_id).to eq(1)
      expect(one.avatar.not_nil!.avatar_url).to eq("jon.png")

      expect(two.id).to eq(2)
      expect(two.name).to eq("Bob")
      expect(two.avatar).to be_a(Orb::AvatarsRelation)
      expect(two.avatar.not_nil!.id).to eq(101)
      expect(two.avatar.not_nil!.user_id).to eq(2)
      expect(two.avatar.not_nil!.avatar_url).to eq("bob.jpg")

      expect(three.id).to eq(3)
      expect(three.name).to eq("Mark")
      expect(three.email).to eq("mark@snow")
      expect(three.created_at).to eq(now)
      expect(three.avatar).to be nil
    end
  end
end
