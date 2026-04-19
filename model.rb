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



helpers do
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
end

#Fight 
helpers do
  def damage_data(id)
    db = connect_to_db('db/databas.db')
    @enemiesData = db.execute("SELECT * FROM enemies WHERE id = ?",id)
    @itemsData = db.execute("SELECT * FROM items")
    return @enemiesData, @itemsData
  end
end


def update_user_health(enemyDamage, user_id)
  db = connect_to_db('db/databas.db')
  db.execute("UPDATE users SET health=health-? WHERE id =?",[enemyDamage, user_id])
end

def update_enemy_health(itemsDamg,id)
  db = connect_to_db('db/databas.db')
  db.execute("UPDATE enemies SET health=health-? WHERE id = ?",[@itemsDamg, id])

end



#Shop
helpers do
  def user_data(user_id)
    db = connect_to_db('db/databas.db')
    @usersData = db.execute("SELECT * FROM users WHERE id = ?", user_id).first
    # @itemsData = db.execute("SELECT * FROM items")
    return @usersData
  end
end

helpers do
  def item_data()
    db = connect_to_db('db/databas.db')
    # @usersData = db.execute("SELECT * FROM users WHERE id = ?", user_id).first
    @itemsData = db.execute("SELECT * FROM items")
    return @itemsData
  end
end


def unique_items_checker(users_id, id)
  db = connect_to_db('db/databas.db')
  itemExistCheck = db.execute("SELECT * FROM users_items WHERE users_id = ? AND items_id = ?",[users_id, id]).first
  return itemExistCheck
end

def buy_item(cost, users_id) 
  db = connect_to_db('db/databas.db')
  db.execute("UPDATE users SET money=money-? WHERE id = ?",[cost, users_id])
  # db.execute("INSERT INTO users_items (users_id, items_id) VALUES (?,?)",[users_id, id] )
  # return 
end

def get_item(users_id,id)
  db = connect_to_db('db/databas.db')
  db.execute("INSERT INTO users_items (users_id, items_id) VALUES (?,?)",[users_id, id] )

end