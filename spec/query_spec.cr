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
