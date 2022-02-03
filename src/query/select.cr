require "../orb"
require "./fragment"

module Orb
  class Query
    struct Select
      property columns : Array(String)
      property fragment : Fragment?

      def initialize(@columns = [] of String, @fragment = nil)
      end

      def values
        [] of Orb::TYPES
      end

      def to_sql(position)
        return render_fragment(position) if @fragment

        "SELECT #{@columns.join(", ")}"
      end

      private def render_fragment(position)
        "SELECT #{@fragment.not_nil!.to_sql(position)}"
      end
    end
  end
end
