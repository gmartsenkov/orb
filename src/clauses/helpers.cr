require "../**"

module Orb
  class Clauses
    module Helpers
      extend self

      macro fragment(query, values)
        Orb::Clauses::Fragment.new({{query}}, {{values}} of Orb::TYPES)
      end

      macro fragment(query)
        Orb::Clauses::Fragment.new({{query}}, [] of Orb::TYPES)
      end
    end
  end
end
