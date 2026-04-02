require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'


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
  itemsDamg = params[:itemsDamage].to_i
  db = SQLite3:: Database.new("db/databas.db")
  db.results_as_hash = true
  @enemiesData = db.execute("SELECT * FROM enemies WHERE id = ?",id)
  @itemsData = db.execute("SELECT * FROM items")

  slim(:fight)
end

post("/enemies/:id/attack") do
  id = params[:id].to_i
  itemsDamg = params[:itemsDamage].to_i
  db = SQLite3::Database.new("db/databas.db")
  db.execute("UPDATE enemies SET health=health-? WHERE id = ?",[itemsDamg, id])
  redirect("/enemies/#{id}/fight")
end


#STORE🛒💵💰
get("/store") do

  slim(:store)
end