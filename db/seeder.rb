require 'sqlite3'

db = SQLite3::Database.new("databas.db")


def seed!(db)
  puts "Using db file: db/databs.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS users')
  db.execute('DROP TABLE IF EXISTS users_items')
  db.execute('DROP TABLE IF EXISTS items')
  db.execute('DROP TABLE IF EXISTS enemies')

end

def create_tables(db)
            #la till money och alla users har 20 money från början
  db.execute('CREATE TABLE users (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
              username TEXT NOT NULL UNIQUE,
              pwd_digest TEXT NOT NULL,
              adminState BOOLEAN,
              money INTEGER DEFAULT 20,
              health INTEGER DEFAULT 50 ) ')
            #felmeddelande för user_id "NOT NULL"-lös varför 
            #items är typ shop för tillfället, cost måste läggas till. user_id borde nog tas bort
  db.execute('CREATE TABLE items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              damage INT,
              cost INTEGER NOT NULL )')
            #relationstabell för users och items, many to many
  db.execute('CREATE TABLE users_items (
              users_id INT,
              items_id INT,
              PRIMARY KEY (users_id, items_id),
              FOREIGN KEY (users_id) REFERENCES users(id),
              FOREIGN KEY (items_id) REFERENCES items(id) )')
#lägg till rewards som spelaren får när fiendens state är död
   db.execute('CREATE TABLE enemies (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              damage INT,
              health INT,
              state BOOLEAN)')

end




def populate_tables(db)
  #Hårkodad admin user
  db.execute('INSERT INTO users (id, username, pwd_digest, adminState) VALUES ("1","admin", "BCrypt::Password.new(adminPassword)", "true")')

   #ITEMS /SHOP
  db.execute('INSERT INTO items (cost, name, damage) VALUES ("1","Klubba", "10")')
  db.execute('INSERT INTO items (cost, name, damage) VALUES ("2","Svärd", "15")')
  db.execute('INSERT INTO items (cost, name, damage) VALUES ("2","Kniv", "3")')
  #ENEMIES
  db.execute('INSERT INTO enemies (name, damage, health, state) VALUES ("gremlin", "10","50", "alive")')
  db.execute('INSERT INTO enemies (name, damage, health, state) VALUES ("zombie", "15", "20", "alive")')
  db.execute('INSERT INTO enemies (name, damage, health, state) VALUES ("troll", "3", "10", "alive")')
end




seed!(db)





