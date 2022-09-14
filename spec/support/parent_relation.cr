require "../../src/orb"

module Orb
  class ParentRelation
    include Orb::Relation

    schema("parents") do
      attribute :id, Int32?
      attribute :name, String?
      attribute :user_id, Int32?
    end

    constructor
  end
end
