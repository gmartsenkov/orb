module Orb
  class Combine
    macro finished
      {% included_relations = Orb::Relation.includers.map { |x| "#{x}::Query" }.join(" | ").id %}
      {% if included_relations.empty? %}
        alias Queries = Nil
      {% else %}
        alias Queries = {{ included_relations }} | Nil
      {% end %}

      property name : Symbol
      property query : Queries

      def initialize(@name, @query)
      end
    end
  end
end
