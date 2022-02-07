require "../**"

module Orb
  class Clauses
    struct CombineClause
      @clauses : Array(Orb::Query::Clause)

      def initialize(@clauses)
      end

      def call
        clauses = @clauses

        clauses = combine_select_distinct(clauses) if select? && distinct?
        clauses = qualify_select(clauses) if select? && from?
        clauses = qualify_distinct(clauses) if distinct? && from?
        clauses = qualify_select_distinct(clauses) if select_distinct?(clauses) && from?
        clauses
      end

      private def qualify_select(clauses)
        select_clause = clauses.find { |c| c.class == Select }.as(Select)
        from_clause = clauses.find { |c| c.class == From }.as(From)

        return clauses if select_clause.fragment

        clauses.delete(select_clause)
        clauses.push(Select.new(select_clause.columns.map { |col| qualify(from_clause.table, col) }))
      end

      private def qualify_distinct(clauses)
        distinct_clause = clauses.find { |c| c.class == Distinct }.as(Distinct)
        from_clause = clauses.find { |c| c.class == From }.as(From)

        clauses.delete(distinct_clause)
        clauses.push(Distinct.new(distinct_clause.columns.map { |col| qualify(from_clause.table, col) }))
      end

      private def qualify_select_distinct(clauses)
        distinct_clause = clauses.find { |c| c.class == SelectDistinct }.as(SelectDistinct)
        from_clause = clauses.find { |c| c.class == From }.as(From)

        clauses.delete(distinct_clause)
        clauses.push(
          SelectDistinct.new(
            distinct_clause.columns.map { |col| qualify(from_clause.table, col) },
            distinct_clause.distinct_columns.map { |col| qualify(from_clause.table, col) })
        )
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

      private def select_distinct?(clauses)
        clauses.map(&.class).includes?(SelectDistinct)
      end

      private def select?
        clause_types.includes?(Select)
      end

      private def distinct?
        clause_types.includes?(Distinct)
      end

      private def from?
        clause_types.includes?(From)
      end

      private def qualify(table, column)
        "#{table}.#{column}"
      end
    end
  end
end
