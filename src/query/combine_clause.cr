require "../**"

module Orb
  class Query
    struct CombineClause
      @clauses : Array(Clauses)

      def initialize(@clauses)
      end

      def call
        clauses = @clauses

        clauses = combine_select_distinct(clauses) if select? && distinct?
        clauses
      end

      private def combine_select_distinct(clauses)
        select_clause = clauses.find { |c| c.class == Select }.as(Select)
        distinct_clause = clauses.find { |c| c.class == Distinct }.as(Distinct)

        clauses.delete(select_clause)
        clauses.delete(distinct_clause)
        clauses.push(SelectDistinct.new(select_clause.columns, distinct_clause.columns))
      end

      private def clause_types
        @clauses.map(&.class)
      end

      private def select?
        clause_types.includes?(Select)
      end

      private def distinct?
        clause_types.includes?(Distinct)
      end
    end
  end
end
