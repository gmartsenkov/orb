require "../../src/orb"

module Orb
  class PostRelation
    include Orb::Relation

    schema("posts") do
      attribute :id, Int32?
      attribute :user_id, Int32?
      attribute :body, String?

      belongs_to :user, Orb::UserRelation, foreign_key: :user_id, target_key: :id
    end

    constructor
  end
end
