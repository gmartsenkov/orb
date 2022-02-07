require "../orb"

module Orb
  class Clauses
    struct OrderBy
      VALID_DIRECTIONS = ["DESC", "ASC"]
      property columns : Array(Tuple(String, String))

      getter values = [] of Orb::TYPES

      def initialize(columns)
        validate_direction(columns)
        @columns = columns
      end

      def to_sql(_position)
        "ORDER BY #{sql}"
      end

      private def sql
        @columns.map { |col, direction| "#{col} #{direction}" }.join(", ")
      end

      private def validate_direction(columns)
        columns.each do |_col, direction|
          unless VALID_DIRECTIONS.includes?(direction.upcase)
            raise "Invalid ORDER BY direction - #{direction}"
          end
        end
      end
    end
  end
end
