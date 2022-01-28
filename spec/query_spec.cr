require "./spec_helper"

struct QueryTest
  property query : Orb::Query
  property result : Orb::Query::Result

  def initialize(@query, @result)
  end
end

macro result(query)
  Orb::Query::Result.new(query: {{query}}, values: [] of Orb::TYPES)
end

macro result(query, values)
  Orb::Query::Result.new(query: {{query}}, values: {{values}} of Orb::TYPES)
end

NOW   = Time.utc
TESTS = [
  QueryTest.new(
    query: Orb::Query.new.select("age", "name", "birthday"),
    result: result("SELECT age, name, birthday")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:age, :name, :birthday).where(:age, :>, 15),
    result: result("SELECT age, name, birthday WHERE age > $1", [15])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:age, :name, :birthday).from("users").where(:age, :>, 15),
    result: result("SELECT age, name, birthday FROM users WHERE age > $1", [15])
  ),
  QueryTest.new(
    query: Orb::Query.new.distinct(:age, :name, :birthday).from(:users).where(:age, :>, 15),
    result: result("SELECT DISTINCT age, name, birthday FROM users WHERE age > $1", [15])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(Orb::Query::Fragment.generate("(age > ? OR age < ?) AND (active = ?)", [18, 99, true])).where(:name, :like, "Jon").from("users"),
    result: result("FROM users WHERE (age > $1 OR age < $2) AND (active = $3) AND name LIKE $4", [18, 99, true, "Jon"])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1),
    result: result("WHERE active = $1", [1])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).where(status: "closed", name: "Jon"),
    result: result("WHERE active = $1 AND status = $2 AND name = $3", [1, "closed", "Jon"])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:created_at, :>=, NOW).where(:name, :like, "Jon"),
    result: result("WHERE created_at >= $1 AND name LIKE $2", [NOW, "Jon"])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).limit(5).offset(3),
    result: result("WHERE active = $1 LIMIT $2 OFFSET $3", [1, 5, 3])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).group_by(:active, :name).limit(5).offset(3),
    result: result("WHERE active = $1 GROUP BY active, name LIMIT $2 OFFSET $3", [1, 5, 3])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).or_where(:active, 2),
    result: result("WHERE active = $1 OR active = $2", [1, 2])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).or_where(active: 2, name: "Jon"),
    result: result("WHERE active = $1 OR active = $2 AND name = $3", [1, 2, "Jon"])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).or_where(Orb::Query::Fragment.generate("(age > ? OR age < ?) AND (active = ?)", [18, 99, true])),
    result: result("WHERE active = $1 OR (age > $2 OR age < $3) AND (active = $4)", [1, 18, 99, true])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).or_where(:age, :>=, 5).where(name: "BOB"),
    result: result("WHERE active = $1 OR age >= $2 AND name = $3", [1, 5, "BOB"])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).or_where(:age, :>=, 5).join(:posts, {:id, :user_id}),
    result: result("INNER JOIN posts ON id = user_id WHERE active = $1 OR age >= $2", [1, 5])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).or_where(:age, :>=, 5).inner_join(:posts, {:id, :user_id}),
    result: result("INNER JOIN posts ON id = user_id WHERE active = $1 OR age >= $2", [1, 5])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).from("users").left_join(:posts, {:id, :user_id}),
    result: result("SELECT id, name FROM users LEFT JOIN posts ON id = user_id")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).from("users").right_join(:posts, {:id, :user_id}),
    result: result("SELECT id, name FROM users RIGHT JOIN posts ON id = user_id")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).from("users").full_join(:posts, {:id, :user_id}),
    result: result("SELECT id, name FROM users FULL JOIN posts ON id = user_id")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).from("users").cross_join(:posts, {:id, :user_id}),
    result: result("SELECT id, name FROM users CROSS JOIN posts ON id = user_id")
  ),
  QueryTest.new(
    query: Orb::Query.new.insert(:users, [:name, :email, :age], ["Jon", "jon@snow", 15] of Orb::TYPES),
    result: result("INSERT INTO users(name, email, age) VALUES ($1, $2, $3)", ["Jon", "jon@snow", 15])
  ),
  QueryTest.new(
    query: Orb::Query.new.update(:users, { name: "bob", age: 15 }),
    result: result("UPDATE INTO users SET name = $1, age = $2", ["bob", 15])
  ),
  QueryTest.new(
    query: Orb::Query.new.update(:users, { name: "bob", age: 15 }).where(id: 1),
    result: result("UPDATE INTO users SET name = $1, age = $2 WHERE id = $3", ["bob", 15, 1])
  ),
  QueryTest.new(
    query: Orb::Query.new.update(:users, Orb::ExampleRelation.new(1, "Jon", "jon@email", NOW)),
    result: result("UPDATE INTO users SET id = $1, name = $2, email = $3, created_at = $4", [1, "Jon", "jon@email", NOW])
  )
]

Spectator.describe Orb::Query do
  describe ".to_result" do
    sample TESTS do |test|
      it "it decodes the message correctly" do
        expect(test.query.to_result).to eq test.result
      end
    end
  end
end
