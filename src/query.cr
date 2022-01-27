require "db"
require "./orb"
require "./query/*"

module Orb
  class Query
    alias Clauses = Select | Distinct | From | GroupBy | Where | Limit | Offset
    @clauses = Array(Clauses).new

    def distinct(*columns)
      @clauses.push(Distinct.new(columns.to_a.map(&.to_s)))
      self
    end

    def select(*columns)
      @clauses.push(Select.new(columns.to_a.map(&.to_s)))
      self
    end

    def group_by(*columns)
      @clauses.push(GroupBy.new(columns.to_a.map(&.to_s)))
      self
    end

    def from(table)
      @clauses.push(From.new(table.to_s))
      self
    end

    def limit(value)
      @clauses.push(Limit.new(value))
      self
    end

    def offset(value)
      @clauses.push(Offset.new(value))
      self
    end

    def where(fragment : Fragment)
      @clauses.push(Where.new(fragment))
      self
    end

    def where(column, operator, value)
      @clauses.push(Where.new(column.to_s, operator.to_s.upcase, value))
      self
    end

    def where(column, value)
      @clauses.push(Where.new(column.to_s, "=", value))
      self
    end

    def where(**conditions)
      @clauses.concat(conditions.map { |key, value| Where.new(key.to_s, "=", value) })
      self
    end

    def to_result
      values = Array(Orb::TYPES).new
      query = String.new
      clauses = @clauses.sort_by(&.priority)
      values = @clauses.flat_map(&.values)
      first_where_clause = @clauses.find { |clause| clause.is_a?(Where) }

      query = clauses.map_with_index do |clause, i|
        position = clauses[0...i].flat_map(&.values).size + 1

        if clause == first_where_clause
          "WHERE " + clause.to_sql(position)
        elsif clause.is_a?(Where)
          "AND " + clause.to_sql(position)
        else
          clause.to_sql(position)
        end
      end.join(" ")

      Result.new(query: query.strip, values: values)
    end
  end
end
