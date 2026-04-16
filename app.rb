require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'


enable :sessions


#USERS, register + login
get("/register") do
  slim(:register)
end

post("/users/new") do
  username= params[:username]
  password= params[:password]
  password_confirm= params[:password_confirm]

  if (password == password_confirm)
    #lägg till användare
    password_digest = BCrypt::Password.create(password) 
    db = SQLite3:: Database.new("db/databas.db")
    db.execute("INSERT INTO users (username, pwd_digest) VALUES (?,?)",[username, password_digest])
    redirect("/login")
  else
    #felhantering
    "Passwords did not match :("
  end

end

get("/login") do
  slim(:login)
end

post("/login") do
  username= params[:username]
  password= params[:password]
  db = SQLite3:: Database.new("db/databas.db")
  db.results_as_hash = true
  result= db.execute("SELECT * FROM users WHERE username=?",username).first
  pwd_digest=result["pwd_digest"]
  id=result["id"]

  if BCrypt::Password.new(pwd_digest)==password
    session[:id] = id 
    redirect("/story")
  else  
    "womp womp, fel lösenord"
  end

end

#test sida för när users är inloggad
get('/story') do
  user_id = session[:id].to_i
  
  db = SQLite3:: Database.new("db/databas.db")
  @username= db.execute("SELECT username from users WHERE id =?", user_id)

  db.results_as_hash = true
  @usersInventory= db.execute("SELECT 
  items.name, items.damage 
  FROM users_items 
  INNER JOIN items ON users_items.items_id =items.id 
  WHERE users_id =?", user_id)
  @userStats = db.execute("SELECT health FROM users WHERE id =?", user_id)

  
  slim(:"story/story_1")
end

get('/story2') do

  slim(:"story/story_2")

end

get('/story3') do
  user_id = session[:id]
  db = SQLite3:: Database.new("db/databas.db")
  db.results_as_hash = true
  @usersInventory= db.execute("SELECT 
  items.name, items.damage 
  FROM users_items 
  INNER JOIN items ON users_items.items_id =items.id 
  WHERE users_id =?", user_id)
  @userStats = db.execute("SELECT health FROM users WHERE id =?", user_id)

  slim(:"story/story_3")

end

#READ📖
get('/') do
  db = SQLite3:: Database.new("db/databas.db")
  db.results_as_hash = true
  @itemsData = db.execute("SELECT * FROM items")
  @enemiesData = db.execute("SELECT * FROM enemies")

  
  slim(:index) 
end

#CREATE🔥📄
get('/new') do 
  slim(:new)
end

post('/new') do
  newItemsName = params[:itemsName]
  newItemsDamg = params[:itemsDamg]
  newItemsType = params[:itemsType]

  p "Användaren vill skapa #{newItemsName} med damage #{newItemsDamg} och type id #{newItemsType} "

  db = SQLite3::Database.new("db/databas.db")
  db.execute("INSERT INTO items (type_id, name, damage) VALUES (?,?,?)", [newItemsType,newItemsName,newItemsDamg])
  redirect("/") 

end

#UPDATE🔁 
get('/items/:id/edit') do
  db = SQLite3::Database.new("db/databas.db")

  db.results_as_hash = true
  id = params[:id].to_i
  @update_items = db.execute("SELECT * FROM items WHERE id=?",id).first
  slim(:edit)
end

post('/items/:id/update') do
  id = params[:id]
  name = params[:name]
  damage = params[:damage]
  # type_id = params[:type_id]

  db = SQLite3::Database.new("db/databs.db")
  db.execute("UPDATE items SET name=?, damage=? WHERE id=?",[name,damage,id])
  redirect('/')

end

#DELETE🗑️
post('/items/:id/delete') do 
  id = params[:id].to_i
  db = SQLite3::Database.new("db/databas.db")
  db.execute("DELETE FROM items WHERE id = ?",id)
  redirect("/")
end

#FIGHT!🤺⚔️
get('/enemies/:id/fight') do
  id = params[:id].to_i
  user_id = session[:id]
  @itemsDamg = params[:itemsDamage].to_i
  db = SQLite3:: Database.new("db/databas.db")
  db.results_as_hash = true
  @enemiesData = db.execute("SELECT * FROM enemies WHERE id = ?",id)
  @itemsData = db.execute("SELECT * FROM items")
  @usersInventory= db.execute("SELECT 
  items.name, items.damage 
  FROM users_items 
  INNER JOIN items ON users_items.items_id =items.id 
  WHERE users_id =?", user_id)
  @userStats = db.execute("SELECT health FROM users WHERE id =?", user_id)
 

   if @userStats[0]["health"] <= 0
      redirect("/game_over")
  end
  
  if @enemiesData[0]["health"] <= 0
    redirect("story3")
  end

 

  slim(:fight)
end

post("/enemies/:id/attack") do
  id = params[:id].to_i
  user_id = session[:id]
  @itemsDamg = params[:itemsDamage].to_i
  enemyDamage= params[:enemyDamage].to_i

  db = SQLite3::Database.new("db/databas.db")
  @itemsData = db.execute("SELECT * FROM items")
  
  db.execute("UPDATE users SET health=health-? WHERE id =?",[enemyDamage, user_id])
  db.execute("UPDATE enemies SET health=health-? WHERE id = ?",[@itemsDamg, id])
  redirect("/enemies/#{id}/fight")
end 

get("/game_over") do
  slim(:gameOver)
end


#SHOP🛒💵💰
get("/shop") do
  #användarens id, vem som är inloggad
  user_id = session[:id]
  db = SQLite3:: Database.new("db/databas.db")
  db.results_as_hash = true
  @itemsData = db.execute("SELECT * FROM items")
  @usersData = db.execute("SELECT * FROM users WHERE id = ?", user_id).first
  
  @usersInventory= db.execute("SELECT 
  items.name, items.damage 
  FROM users_items 
  INNER JOIN items ON users_items.items_id =items.id 
  WHERE users_id =?", user_id)
  @userStats = db.execute("SELECT health FROM users WHERE id =?", user_id)
  slim(:shop)
end

post("/shop/:id/buy") do
  #items id
  id = params[:id].to_i
  users_id = session[:id]
  cost = params[:cost].to_i
  db = SQLite3:: Database.new("db/databas.db")
  db.results_as_hash = true

  itemExistCheck = db.execute("SELECT * FROM users_items WHERE users_id = ? AND items_id = ?",[users_id, id]).first
  if itemExistCheck != nil
    # "Du äger redan detta item"

  else 
    db.execute("UPDATE users SET money=money-? WHERE id = ?",[cost, users_id])
    db.execute("INSERT INTO users_items (users_id, items_id) VALUES (?,?)",[users_id, id] )
  end

  redirect("/shop")


end