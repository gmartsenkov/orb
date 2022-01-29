require "spectator"
require "./support/**"
require "../src/**"
require "pg"
require "dotenv"

Dotenv.load ".env.test"

DATABASE_URL = ENV.fetch("DATABASE_URL")
Orb.connect(DATABASE_URL)

Spectator.configure do |config|
  config.before_suite { Orb.connect(DATABASE_URL) }
  config.after_suite { Orb.disconnect }

  config.around_each do |example|
    Orb.db.transaction do |tx|
      begin
        Orb.conn = tx.connection

        example.call
      ensure
        Orb.conn = nil
        tx.rollback
      end
    end
  end
end
