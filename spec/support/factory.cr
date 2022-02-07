require "./**"

module Factory
  extend self

  def build(user : Orb::UserRelation)
    Orb.exec(Orb::Query(Orb::UserRelation).new.insert(user))
  end
end
