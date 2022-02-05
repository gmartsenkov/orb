require "../src/orb"
require "./*"
require "benchmark"
require "dotenv"
require "pg"
require "clear"


Dotenv.load ".env.test"
DATABASE_URL = ENV.fetch("DATABASE_URL")

Orb.connect(DATABASE_URL)
Clear::SQL.init(DATABASE_URL)

(0..10000).each do |x|
  UserRelation.query.insert(:users, {name: "Jon - #{x}", email: "jon@snow", age: 15}).commit
end

Benchmark.ips(warmup: 2, calculation: 5) do |b|
  b.report("simple query Orb") { UserRelation.query.to_a }
  b.report("simple query Clear") { UserModel.query.to_a }
end
