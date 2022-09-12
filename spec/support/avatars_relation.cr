require "../../src/orb"

module Orb
  class AvatarsRelation
    include Orb::Relation

    schema("user_avatar") do
      attribute :id, Int32?
      attribute :user_id, Int32?
      attribute :avatar_url, String?
      attribute :created_at, Time?
    end

    constructor
  end
end
