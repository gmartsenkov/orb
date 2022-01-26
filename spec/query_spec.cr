require "./spec_helper"

struct QueryTest
  property query : Orb::Query
  property result : Orb::Query::Result

  def initialize(@query, @result)
  end
end

macro result(query, values)
  Orb::Query::Result.new(query: {{query}}, values: {{values}} of Orb::TYPES)
end

NOW   = Time.utc
TESTS = [
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1),
    result: result("active = $1", [1])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:active, 1).where(status: "closed", name: "Jon"),
    result: result("active = $1 AND status = $2 AND name = $3", [1, "closed", "Jon"])
  ),
  QueryTest.new(
    query: Orb::Query.new.where(:created_at, :>=, NOW).where(:name, :like, "Jon"),
    result: result("created_at >= $1 AND name LIKE $2", [NOW, "Jon"])
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
