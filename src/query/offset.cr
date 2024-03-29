require "../orb"

module Orb
  class Query
    struct Offset
      property offset : Int32

      def initialize(@offset)
      end

      def to_sql(position)
        "OFFSET $#{position}"
      end

      def values
        [@offset]
      end
    end
  end
end
