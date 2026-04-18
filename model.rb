#HELPER funktioner
def connect_to_db(path)
 db = SQLite3::Database.new(path)
 db.results_as_hash = true
 return db
end


def register_user(username,password)
  password_digest = BCrypt::Password.create(password) 
  db = connect_to_db('db/databas.db')
  db.execute("INSERT INTO users (username, pwd_digest) VALUES (?,?)",[username, password_digest])
end

def login_user(username,password)
 db = connect_to_db('db/databas.db')
  result= db.execute("SELECT * FROM users WHERE username=?",username).first
  pwd_digest=result["pwd_digest"]
  id=result["id"]
  return pwd_digest, id
end


def stats_inventory(user_id)
  db = connect_to_db('db/databas.db')
  # user_id = session[:id].to_i
  @usersInventory= db.execute("SELECT 
  items.name, items.damage 
  FROM users_items 
  INNER JOIN items ON users_items.items_id =items.id 
  WHERE users_id =?", user_id)
  @userStats = db.execute("SELECT health FROM users WHERE id =?", user_id)
  return @usersInventory, @userStats
end
