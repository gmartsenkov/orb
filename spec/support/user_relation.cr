require "../../src/orb"

module Orb
  class UserRelation
    include Orb::Relation

    schema("users") do
      attribute :id, Int32?
      attribute :name, String?
      attribute :email, String?
      attribute :created_at, Time?

      has_one :avatar, Orb::AvatarsRelation, foreign_key: :id, target_key: :user_id
      has_one :parent, Orb::ParentRelation, foreign_key: :id, target_key: :user_id
      has_many :posts, Orb::PostRelation, foreign_key: :id, target_key: :user_id
    end

    constructor
  end
end
