require "./**"

module Factory
  extend self

  def build(user : Orb::ExampleRelation)
    Orb.exec(Orb::Query.new.insert(user))
  end
end
