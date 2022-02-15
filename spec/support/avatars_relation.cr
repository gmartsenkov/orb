require "../../src/orb"

module Orb
  class AvatarsRelation < Orb::Relation
    table "user_avatar"

    attribute :id, Int32?
    attribute :user_id, Int32?
    attribute :avatar_url, String?
    attribute :created_at, Time?

    register_associations

    def initialize(@id = nil, @user_id = nil, @avatar_url = nil, @created_at = nil)
    end
  end
end
