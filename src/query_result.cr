require "./orb"

module Orb
  struct QueryResult
    getter query : String
    getter values : Array(Orb::TYPES)

    def initialize(@query, @values = Array(Orb::TYPES).new)
    end
  end
end
