require "db"
require "./orb"
require "./query/*"

module Orb
  class Query
    enum LogicalOperator
      And
      Or
    end

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

    {% for pair, _ in [{"where", "LogicalOperator::And"}, {"or_where", "LogicalOperator::Or"}] %}
      def {{pair[0].id}}(fragment : Fragment)
        @clauses.push(Where.new(fragment, {{pair[1].id}}))
        self
      end

      def {{pair[0].id}}(column, operator, value)
        @clauses.push(Where.new(column.to_s, operator.to_s.upcase, value, {{pair[1].id}}))
        self
      end

      def {{pair[0].id}}(column, value)
        @clauses.push(Where.new(column.to_s, "=", value, {{pair[1].id}}))
        self
      end

      def {{pair[0].id}}(**conditions)
        clauses = conditions.to_a.map_with_index do |condition, i|
          operator = i.zero? ? {{pair[1].id}} : LogicalOperator::And
          Where.new(condition[0].to_s, "=", condition[1], operator)
        end

        @clauses.concat(clauses)
        self
      end
    {% end %}

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
          clause.logical_operator + " " + clause.to_sql(position)
        else
          clause.to_sql(position)
        end
      end.join(" ")

      Result.new(query: query.strip, values: values)
    end
  end
end
