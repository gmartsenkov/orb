require "../**"

module Orb
  class Query
    module Helpers
      extend self

      macro fragment(query, values)
        Orb::Query::Fragment.new({{query}}, {{values}} of Orb::TYPES)
      end

      macro fragment(query)
        Orb::Query::Fragment.new({{query}}, [] of Orb::TYPES)
      end
    end
  end
end
