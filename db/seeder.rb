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
  db.execute('DROP TABLE IF EXISTS exempel')
  db.execute('DROP TABLE IF EXISTS users')
  db.execute('DROP TABLE IF EXISTS items')
  db.execute('DROP TABLE IF EXISTS enemies')

end

def create_tables(db)
  db.execute('CREATE TABLE exempel (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              description TEXT,
              state BOOLEAN)')

  db.execute('CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL,
              pwd_digest TEXT) ')
  # inte klar än(?) ta bort type_id, vad gör ens det?
  db.execute('CREATE TABLE items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type_id INTEGER,
              name TEXT NOT NULL,
              damage INT )')
#lägg till rewards som spelaren får när fiendens state är död
   db.execute('CREATE TABLE enemies (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type_id INTEGER,
              name TEXT NOT NULL,
              damage INT,
              health INT,
              state BOOLEAN)')

end

def populate_tables(db)
  db.execute('INSERT INTO exempel (name, description, state) VALUES ("Köp mjölk", "3 liter mellanmjölk, eko",false)')
  db.execute('INSERT INTO exempel (name, description, state) VALUES ("Köp julgran", "En rödgran",false)')
  db.execute('INSERT INTO exempel (name, description, state) VALUES ("Pynta gran", "Glöm inte lamporna i granen och tomten",false)')
end


def populate_tables(db)
  #ITEMS
  db.execute('INSERT INTO items (type_id, name, damage) VALUES ("1","Klubba", "10")')
  db.execute('INSERT INTO items (type_id, name, damage) VALUES ("2","Svärd", "15")')
  db.execute('INSERT INTO items (type_id, name, damage) VALUES ("2","Kniv", "3")')
  #ENEMIES
  db.execute('INSERT INTO enemies (type_id, name, damage, health, state) VALUES ("2","gremlin", "10","50", "alive")')
  db.execute('INSERT INTO enemies (type_id, name, damage, health, state) VALUES ("1","zombie", "15", "20", "alive")')
  db.execute('INSERT INTO enemies (type_id, name, damage, health, state) VALUES ("2","troll", "3", "10", "alive")')
end




seed!(db)





