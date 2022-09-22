require "db"
require "./orb"
require "./combine"

module RelationQuery
  macro included
    @combines = Array(Orb::Combine).new

    {% fields = parse_type("#{@type.id}::Fields".gsub(/::Query/, "")).resolve.all_subclasses.map(&.name.id.underscore.split("::").last.id) %}
    {% relationships = parse_type("#{@type.id}::Relationships".gsub(/::Query/, "")).resolve.all_subclasses.map(&.name.id.underscore.split("::").last.id) %}
    {% relationship_classes = parse_type("#{@type.id}::Relationships".gsub(/::Query/, "")).resolve.all_subclasses %}

      {% for pair, _ in [{"where", "Orb::Query::LogicalOperator::And"}, {"or_where", "Orb::Query::LogicalOperator::Or"}] %}
      def {{pair[0].id}}({{*fields.map do |field|
                             "#{field.id} = Orb::Query::Special::None".id
                           end}})

        {% for field in fields %}
          unless {{field.id}}.is_a?(Orb::Query::Special::None)
            if {{field.id}}.is_a?(Array)
              @query.{{pair[0].id}}({{ field.symbolize }}, "IN", {{ field.id }}.map(&.as(Orb::TYPES)))
            else
              @query.{{pair[0].id}}({{ field.symbolize }}, "=", {{ field.id }}.as?(Orb::TYPES))
            end
          end
        {% end %}
        self
      end

      def {{pair[0].id}}(fragment : Orb::Query::Fragment)
        @query.{{pair[0].id}}(fragment)
        self
      end

      def {{pair[0].id}}(column, value)
        @query.{{pair[0].id}}(column, value)
        self
      end

      def {{pair[0].id}}(column, operator : String | Symbol, value)
        @query.{{pair[0].id}}(column, operator, value)
        self
      end
      {% end %}

      def combine({{*relationships.map do |field|
                      "#{field.id} = Orb::Query::Special::None".id
                    end}})


        {% for relationship in parse_type("#{@type.id}::Relationships".gsub(/::Query/, "")).resolve.all_subclasses %}
          {% field = relationship.name.id.underscore.split("::").last.id %}
          unless {{field.id}}.is_a?(Orb::Query::Special::None)
            @combines << Orb::Combine.new(name: {{field.id.symbolize}}, query: {{field.id}}.as?(Orb::Combine::Queries))
          end
        {% end %}
        self
      end

      def to_a
        result = @query.to_a.as(Array({{parse_type("#{@type.id}".gsub(/::Query/, "")).resolve}}))
        resolve_combines(result)
        result
      end

      def resolve_combines(results)
        @combines.each do |combine|
          {% for relationship in relationship_classes %}
            {% foreign_key = parse_type("#{relationship.id}::FOREIGN_KEY").resolve.id %}
            {% target_key = parse_type("#{relationship.id}::TARGET_KEY").resolve.id %}
            {% relation_class = parse_type("#{relationship.id}::RELATION").resolve.id %}
            {% relationship_name = parse_type("#{relationship.id}::NAME").resolve.id %}
            {% relation_type = parse_type("#{relationship.id}::TYPE").resolve.id %}

            if {{relationship_name.symbolize}} == combine.name
              related = combine
                        .query
                        .not_nil!
                        .where({{target_key.symbolize}}, "IN", results.map(&.{{foreign_key}}))
                        .to_a
                        .group_by { |x| x.as({{ relation_class }} ).{{target_key}} }

              related.each do |id, values|
                results.select { |x| x.{{foreign_key}} == id }.each do |found|
                  next unless found
                  {% if relation_type.symbolize == :has_one %}
                    found.{{relationship_name}} = values.first.as({{relation_class}})
                  {% end %}
                  {% if relation_type.symbolize == :belongs_to %}
                    found.{{relationship_name}} = values.first.as({{relation_class}})
                  {% end %}
                  {% if relation_type.symbolize == :has_many %}
                    found.{{relationship_name}} = values.as(Array({{relation_class}}))
                  {% end %}
                end
              end
            end
          {% end %}
        end
      end
    end

  def select(*columns)
    @query.select(*columns)
    self
  end

  def limit(number)
    @query.limit(number)
    self
  end

  def offset(number)
    @query.offset(number)
    self
  end

  def join(table, columns)
    @query.join(table, columns)
    self
  end

  def order_by(col)
    @query.order_by(col)
    self
  end

  def count
    @query.count
  end

  def commit
    @query.commit
  end

  def to_result
    @query.to_result
  end
end

module Orb
  module Relation
    include DB::Serializable

    @@column_names = Array(String).new

    macro included
      class Fields
      end

      abstract class Relationships
        abstract def name : Symbol
        abstract def direction : Symbol
        abstract def foreign_key : Symbol
        abstract def target_key : Symbol
      end

      def self.query
        Query.new
      end

      def self.column_names
        @@column_names
      end
    end

    macro schema(table_name, &block)
      include DB::Serializable

      def self.table_name
        {{table_name}}
      end

      {{ yield }}
    end

    macro constructor
      {% fields = parse_type("#{@type.id}::Fields").resolve.all_subclasses %}
      {% relationships = parse_type("#{@type.id}::Relationships").resolve.all_subclasses %}
      def initialize({{*(fields + relationships).map do |field|
                         name = "@#{field.name.id.underscore.split("::").last.id}"
                         "#{name.id} = nil".id
                       end}})
      end

      class Query
        @query : Orb::Query

        alias Relation = {{ parse_type("#{@type.id}").resolve }}
        include RelationQuery

        def initialize
          @query = Orb::Query.new.select(Relation.column_names).from(Relation.table_name).map_to(Relation)
        end

        def delete
          @query.delete(Relation.table_name)
          self
        end
      end
    end

    macro attribute(name, type)
      @@column_names.push({{name}}.to_s)

      class Fields::{{ name.camelcase.id }} < Fields; end

      property {{name.id}} : {{type}}
    end

    macro has_one(name, relation, **opts)
      class Relationships::{{ name.camelcase.id }} < Relationships
        FOREIGN_KEY = {{ opts[:foreign_key] }}
        TARGET_KEY = {{ opts[:target_key] }}
        RELATION = {{ relation.id }}
        NAME = {{ name.id }}
        TYPE = :has_one

        def name : Symbol
          {{ name.id.symbolize }}
        end

        def direction : Symbol
          :has_one
        end

        def foreign_key : Symbol
          {{ opts[:foreign_key] }}
        end

        def target_key : Symbol
          {{ opts[:target_key] }}
        end
      end

      @[DB::Field(ignore: true)]
      property {{name.id}} : {{relation}} | Nil
    end

    macro belongs_to(name, relation, **opts)
      class Relationships::{{ name.camelcase.id }} < Relationships
        FOREIGN_KEY = {{ opts[:foreign_key] }}
        TARGET_KEY = {{ opts[:target_key] }}
        RELATION = {{ relation.id }}
        NAME = {{ name.id }}
        TYPE = :belongs_to

        def name : Symbol
          {{ name.id.symbolize }}
        end

        def direction : Symbol
          :belongs_to
        end

        def foreign_key : Symbol
          {{ opts[:foreign_key] }}
        end

        def target_key : Symbol
          {{ opts[:target_key] }}
        end
      end

      @[DB::Field(ignore: true)]
      property {{name.id}} : {{relation}} | Nil
    end

    macro has_many(name, relation, **opts)
      class Relationships::{{ name.camelcase.id }} < Relationships
        FOREIGN_KEY = {{ opts[:foreign_key] }}
        TARGET_KEY = {{ opts[:target_key] }}
        RELATION = {{ relation.id }}
        NAME = {{ name.id }}
        TYPE = :has_many

        def name : Symbol
          {{ name.id.symbolize }}
        end

        def direction : Symbol
          :has_many
        end

        def foreign_key : Symbol
          {{ opts[:foreign_key] }}
        end

        def target_key : Symbol
          {{ opts[:target_key] }}
        end
      end

      @[DB::Field(ignore: true)]
      property {{name.id}} : Array({{relation}}) | Nil
    end

    def to_h : Hash(String | Symbol, Orb::TYPES)
      converted = {} of (String | Symbol) => Orb::TYPES
      hash_attr = {% begin %}
        {% h = {} of (String | Symbol) => Orb::TYPES %}
        {% fields = parse_type("#{@type.id}::Fields").resolve.all_subclasses.map { |klass| "#{klass.name.id.underscore.split("::").last.id}" } %}
        {% unless fields.empty? %}
          {% fields.each { |field| h[field] = field.id } %}
          {{h}}
        {% else %}
          converted
        {% end %}
      {% end %}
      hash_attr.each { |k, v| converted[k] = v }
      converted
    end
  end
end
