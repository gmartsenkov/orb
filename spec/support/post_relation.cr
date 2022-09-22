require "../../src/orb"

module Orb
  class PostRelation
    include Orb::Relation

    schema("posts") do
      attribute :id, Int32?
      attribute :user_id, Int32?
      attribute :body, String?
    end

    constructor
  end
end
