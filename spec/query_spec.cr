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

include Orb::Query::Helpers

NOW   = Time.utc
TESTS = [
  QueryTest.new(
    query: Orb::Query.new.select("age", "name", "birthday"),
    result: result("SELECT age, name, birthday")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :content).from(:users).from(:posts),
    result: result("SELECT posts.id, posts.content FROM posts")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:age, :name, :birthday).select(:id).from(:users),
    result: result("SELECT users.id FROM users")
  ),
  QueryTest.new(
    query: Orb::Query.new.distinct(:age, :name, :birthday).distinct(:id).from(:users),
    result: result("SELECT DISTINCT users.id FROM users")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:age, :name, :birthday).where(:age, :>, 15),
    result: result("SELECT age, name, birthday WHERE age > $1", [15])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:age, :name, :birthday).where(:id, [1, 2, 3]),
    result: result("SELECT age, name, birthday WHERE id IN ($1, $2, $3)", [1, 2, 3])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:age, :name, :birthday).where(id: [1, 2, 3], age: 5),
    result: result("SELECT age, name, birthday WHERE id IN ($1, $2, $3) AND age = $4", [1, 2, 3, 5])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:age, :name, :birthday).from("users").where(:age, :>, 15),
    result: result("SELECT users.age, users.name, users.birthday FROM users WHERE age > $1", [15])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:age, :name, :birthday).from("users").where(:age, "IN", [15, 16, 17]),
    result: result("SELECT users.age, users.name, users.birthday FROM users WHERE age IN ($1, $2, $3)", [15, 16, 17])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id).select(Orb::UserRelation),
    result: result("SELECT users.id, users.name, users.email, users.created_at FROM users")
  ),
  QueryTest.new(
    query: Orb::Query.new.distinct(:age, :name, :birthday).from(:users).where(:age, :>, 15),
    result: result("SELECT DISTINCT users.age, users.name, users.birthday FROM users WHERE age > $1", [15])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(fragment("(age > ? OR age < ?) AND (active = ?)", [18, 99, true])).where(:name, :like, "Jon").from("users"),
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
    query: Orb::Query.new.where(:active, 1).limit(2).limit(5).offset(0).offset(3),
    result: result("WHERE active = $1 LIMIT $2 OFFSET $3", [1, 5, 3])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).group_by(:active, :name).limit(5).offset(3),
    result: result("WHERE active = $1 GROUP BY active, name LIMIT $2 OFFSET $3", [1, 5, 3])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id).group_by(:active, :name).from(:users),
    result: result("SELECT users.id FROM users GROUP BY active, name")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(fragment("COUNT(*)")).from(:users),
    result: result("SELECT COUNT(*) FROM users")
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
    query: Orb::Query.new.where(:active, 1).or_where(fragment("(age > ? OR age < ?) AND (active = ?)", [18, 99, true])),
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
    query: Orb::Query.new.select(:id, :name).from("users").left_join(:posts, {:id, :user_id}).join(:accounts, {:account_id, :id}),
    result: result("SELECT users.id, users.name FROM users LEFT JOIN posts ON id = user_id INNER JOIN accounts ON account_id = id")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).from("users").left_join(:posts, {:id, :user_id}),
    result: result("SELECT users.id, users.name FROM users LEFT JOIN posts ON id = user_id")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).from("users").right_join(:posts, {:id, :user_id}),
    result: result("SELECT users.id, users.name FROM users RIGHT JOIN posts ON id = user_id")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).from("users").full_join(:posts, {:id, :user_id}),
    result: result("SELECT users.id, users.name FROM users FULL JOIN posts ON id = user_id")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).from("users").cross_join(:posts, {:id, :user_id}),
    result: result("SELECT users.id, users.name FROM users CROSS JOIN posts ON id = user_id")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:random).insert(:users, {name: "Jon", email: "jon@snow", age: 15}),
    result: result("INSERT INTO users(name, email, age) VALUES ($1, $2, $3)", ["Jon", "jon@snow", 15])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:random).insert(:users, {id: 1}).insert(:users, {name: "Jon", email: "jon@snow", age: 15}),
    result: result("INSERT INTO users(name, email, age) VALUES ($1, $2, $3)", ["Jon", "jon@snow", 15])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:random).insert(Orb::UserRelation.new(id: 1)).insert(Orb::UserRelation.new(name: "Jon", email: "jon@snow")),
    result: result(
      "INSERT INTO users(id, name, email, created_at) VALUES ($1, $2, $3, $4)",
      [nil, "Jon", "jon@snow", nil]
    )
  ),
  QueryTest.new(
    query: Orb::Query.new.update(:users, {name: "bob", age: 15}),
    result: result("UPDATE users SET name = $1, age = $2", ["bob", 15])
  ),
  QueryTest.new(
    query: Orb::Query.new.update(:users, {id: 1}).update(:users, {name: "bob", age: 15}),
    result: result("UPDATE users SET name = $1, age = $2", ["bob", 15])
  ),
  QueryTest.new(
    query: Orb::Query.new.update(:users, {name: "bob", age: 15}).where(id: 1),
    result: result("UPDATE users SET name = $1, age = $2 WHERE id = $3", ["bob", 15, 1])
  ),
  QueryTest.new(
    query: Orb::Query.new.update(Orb::UserRelation.new(1, "Jon", "jon@email", NOW)),
    result: result("UPDATE users SET id = $1, name = $2, email = $3, created_at = $4", [1, "Jon", "jon@email", NOW])
  ),
  QueryTest.new(
    query: Orb::Query.new.update(Orb::UserRelation.new(1, "Jon", "jon@email", NOW)).where(id: 1),
    result: result("UPDATE users SET id = $1, name = $2, email = $3, created_at = $4 WHERE id = $5", [1, "Jon", "jon@email", NOW, 1])
  ),
  QueryTest.new(
    query: Orb::Query.new.update(Orb::UserRelation.new(1, "Mark", "mark@email")).update(Orb::UserRelation.new(1, "Jon", "jon@email", NOW)),
    result: result("UPDATE users SET id = $1, name = $2, email = $3, created_at = $4", [1, "Jon", "jon@email", NOW])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:random).multi_insert(:users, [{id: 1}]).multi_insert(:users, [{name: "Jon", age: 15, email: "jon@snow"}, {name: "Bob", age: 22, email: "bob@snow"}]),
    result: result("INSERT INTO users(name, age, email) VALUES ($1, $2, $3), ($4, $5, $6)", ["Jon", 15, "jon@snow", "Bob", 22, "bob@snow"])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:random).multi_insert([Orb::UserRelation.new(name: "Mark")]).multi_insert(
      [Orb::UserRelation.new(name: "Jon", email: "jon@snow"), Orb::UserRelation.new(name: "Bob", email: "bob@snow")]),
    result: result("INSERT INTO users(id, name, email, created_at) VALUES ($1, $2, $3, $4), ($5, $6, $7, $8)",
      [nil, "Jon", "jon@snow", nil, nil, "Bob", "bob@snow", nil])
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name, :age).distinct(:id, :name).from(:users),
    result: result("SELECT DISTINCT ON(users.id, users.name) users.id, users.name, users.age FROM users")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).order_by(:name).from(:users),
    result: result("SELECT users.id, users.name FROM users ORDER BY name ASC")
  ),
  QueryTest.new(
    query: Orb::Query.new.select(:id, :name).order_by([{"name", "desc"}, {"id", "desc"}]).from(:users),
    result: result("SELECT users.id, users.name FROM users ORDER BY name desc, id desc")
  ),
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
