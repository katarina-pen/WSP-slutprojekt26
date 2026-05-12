# Contains all database interaction methods for the application
module Model 
  
  # Connects to the SQLite3 database
  #
  # @param [String] path The path to the database file
  #
  # @return [SQLite3::Database] the database connection
  def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
  end

  # Registers a new admin user in the database
  #
  # @param [String] username The admin's username
  # @param [String] password The admin's password in plaintext
  #
  # @return [nil]
  def register_admin(username,password)
    password_digest = BCrypt::Password.create(password) 
    db = SQLite3::Database.new("databas.db")
    db.execute("INSERT INTO users (username, pwd_digest, adminState) VALUES (?,?,?)",[username, password_digest, 1])
  end

  # Registers a new user in the database
  #
  # @param [String] username The user's username
  # @param [String] password The user's password in plaintext
  #
  # @return [nil]
  def register_user(username,password)
    password_digest = BCrypt::Password.create(password) 
    db = connect_to_db('db/databas.db')
    db.execute("INSERT INTO users (username, pwd_digest, adminState) VALUES (?,?,?)",[username, password_digest, 0])
  end

  # Fetches password digest and id for a user
  #
  # @param [String] username The user's username
  # @param [String] password The user's password in plaintext
  #
  # @return [String] pwd_digest The hashed password
  # @return [Integer] id The user's ID
  def login_user(username,password)
    db = connect_to_db('db/databas.db')
    result= db.execute("SELECT * FROM users WHERE username=?",username).first
    pwd_digest=result["pwd_digest"]
    id=result["id"]
    return pwd_digest, id
  end

  # Creates a new item in the database
  #
  # @param [String] newItemsName The name of the item
  # @param [Integer] newItemsDamg The damage value of the item
  #
  # @return [nil]
  def create_items(newItemsName,newItemsDamg,newItemsCost)
    db = connect_to_db('db/databas.db')
    db.execute("INSERT INTO items (name, damage, cost) VALUES (?,?,?)", [newItemsName,newItemsDamg, newItemsCost])
  end

  # Fetches a single item from the database
  #
  # @param [Integer] id The item's ID
  #
  # @return [Hash] the item's data
  def edit_items(id) 
    db = connect_to_db('db/databas.db')
    @update_items = db.execute("SELECT * FROM items WHERE id=?",id).first
  end

  # Updates an existing item in the database
  #
  # @param [String] name The new name of the item
  # @param [Integer] damage The new damage value
  # @param [Integer] id The item's ID
  #
  # @return [nil]
  def update_items(name, damage,id)
    db = connect_to_db('db/databas.db')
    db.execute("UPDATE items SET name=?, damage=? WHERE id=?",[name,damage,id])

  end

  # Deletes an item from the database
  #
  # @param [Integer] id The item's ID
  #
  # @return [nil]
  def delete_items(id)
    db = connect_to_db('db/databas.db')
    db.execute("DELETE FROM items WHERE id = ?",id)
  end

  # Updates a user's health in the database
  #
  # @param [Integer] enemyDamage The damage dealt by the enemy
  # @param [Integer] user_id The user's ID
  #
  # @return [nil]
  def update_user_health(enemyDamage, user_id)
    db = connect_to_db('db/databas.db')
    db.execute("UPDATE users SET health=health-? WHERE id =?",[enemyDamage, user_id])
  end

  # Updates an enemy's health in the database
  #
  # @param [Integer] itemsDamg The damage dealt by the player's item
  # @param [Integer] id The enemy's ID
  #
  # @return [nil]
  def update_enemy_health(itemsDamg,id)
    db = connect_to_db('db/databas.db')
    db.execute("UPDATE enemies SET health=health-? WHERE id = ?",[@itemsDamg, id])

  end

  # Checks if a user already owns a specific item
  #
  # @param [Integer] users_id The user's ID
  # @param [Integer] id The item's ID
  #
  # @return [Hash] the existing relation if found
  # @return [nil] if the user does not own the item
  def unique_items_checker(users_id, id)
    db = connect_to_db('db/databas.db')
    itemExistCheck = db.execute("SELECT * FROM users_items WHERE users_id = ? AND items_id = ?",[users_id, id]).first
    return itemExistCheck
  end

  # Deducts the cost of an item from the user's money
  #
  # @param [Integer] cost The cost of the item
  # @param [Integer] users_id The user's ID
  #
  # @return [nil]
  def buy_item(cost, users_id) 
    db = connect_to_db('db/databas.db')
    db.execute("UPDATE users SET money=money-? WHERE id = ?",[cost, users_id])
  end

  # Adds an item to the user's inventory in the relation table
  #
  # @param [Integer] users_id The user's ID
  # @param [Integer] id The item's ID
  #
  # @return [nil]
  def get_item(users_id,id)
    db = connect_to_db('db/databas.db')
    db.execute("INSERT INTO users_items (users_id, items_id) VALUES (?,?)",[users_id, id] )

  end

end