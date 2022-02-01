require "db"
require "./orb"

module Orb
  abstract class Relation
    include DB::Serializable

    @@column_names = Array(String).new

    macro table(name)
      include DB::Serializable

      def self.table_name
        {{name}}
      end
    end

    macro attribute(name, type)
      @@column_names.push({{name}}.to_s)
      property {{name.id}} : {{type}}
    end

    def to_h : Hash(String | Symbol, Orb::TYPES)
      converted = {} of (String | Symbol) => Orb::TYPES
      hash_attr = {% begin %}
        {% h = {} of (String | Symbol) => Orb::TYPES %}
        {% unless @type.instance_vars.empty? %}
          {% @type.instance_vars.map(&.name).each { |field| h[field.stringify] = field.id } %}
          {{h}}
        {% else %}
          converted
        {% end %}
      {% end %}
      hash_attr.each { |k, v| converted[k] = v }
      converted
    end

    def self.query
      Orb::Query.new.select(self).map_to(self)
    end

    def self.column_names
      @@column_names
    end
  end
end
