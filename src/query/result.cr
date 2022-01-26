require "../orb"

module Orb
  class Query
    struct Result
      getter query : String
      getter values : Array(Orb::TYPES)

      def initialize(@query, @values)
      end
    end
  end
end
