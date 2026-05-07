require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'
require 'sinatra/flash'

enable :sessions






#USERS, register + login
get("/register") do
  slim(:register)
end

post("/users/new") do
  username= params[:username]
  password= params[:password]
  password_confirm= params[:password_confirm]
  
  db = connect_to_db('db/databas.db')
  # id = session[:id]
  userExistCheck = db.execute("SELECT * FROM users WHERE username =?",username )
      p "userArray är: #{userExistCheck}"

  if (!userExistCheck.empty?)
    flash[:user_exist] = "Denna användare finns redan! Välje ett annat användarnamn!"
    redirect("/register")
      # p "userArray är: #{userExistCheck}"

  elsif (password.length || password_confirm.length < 4 )
    flash[:short_password] = "Ditt lösenord behöver MINST 4 karaktärer"
    redirect("/register")

  elsif (password == password_confirm)
    register_user(username, password)
    p "Lösenordet är #{password.length}"
    p "LösenordetConfirm är #{password.length}"
    redirect("/login")
  else
    #felhantering
    # "Passwords did not match :("
    flash[:not_match_password] = "Dina lösenord matchar inte!"
    redirect("/register")
    
  end

end

get("/login") do
  slim(:login)
end

post("/login") do
  username= params[:username]
  password= params[:password]

  pwd_digest, id = login_user(username, password)
    
  session[:login_attempt] = 0
  p "Antal login attempt: #{session[:login_attempt]}"
  
  if BCrypt::Password.new(pwd_digest)==password
    session[:id] = id 
    redirect("/story")
  else  
    # "womp womp, fel lösenord"
    session[:login_attempt] += 1
    flash[:wrong_password] = "Fel lösenord :C womp womp"
    redirect("/login")
  end

end


get('/story') do
  
  db = connect_to_db('db/databas.db')
  #Fixa eller ta bort helt 
  # @username= db.execute("SELECT username from users WHERE id =?", user_id)
  @usersInventory, @userStats=stats_inventory(session[:id].to_i)
  
  slim(:"story/story_1")
end

get('/story2') do

  slim(:"story/story_2")

end

get('/story3') do
  @usersInventory, @userStats=stats_inventory(session[:id].to_i)

  slim(:"story/story_3")

end


before('/protected/*') do
 p "These are protected_methods"
   db = connect_to_db('db/databas.db')
    currentUser = session[:id]
    adminState= db.execute("SELECT adminState FROM users WHERE id =?",currentUser)
  # if session[:id] ==  nil
  if adminState ==  nil
    p "Du är inte admin :( Inte välkommen >:("
    #Ingen användare är inloggad
   redirect('/register')
 end
end


#READ📖
get('/protected/home') do

  db = connect_to_db('db/databas.db')
  @enemiesData, @itemsData=damage_data(params[:id].to_i)

  # @itemsData = db.execute("SELECT * FROM items")
  # @enemiesData = db.execute("SELECT * FROM enemies")

  
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

  db = connect_to_db('db/databas.db')
  #jag tog bort type_id, rätta och ta bort det i update o allt
  db.execute("INSERT INTO items (type_id, name, damage) VALUES (?,?,?)", [newItemsType,newItemsName,newItemsDamg])
  redirect("/") 

end

#UPDATE🔁 
get('/items/:id/edit') do
  
  db = connect_to_db('db/databas.db')
  id = params[:id].to_i
  @update_items = db.execute("SELECT * FROM items WHERE id=?",id).first
  slim(:edit)
end

post('/items/:id/update') do
  id = params[:id]
  name = params[:name]
  damage = params[:damage]
  # type_id = params[:type_id]

  db = connect_to_db('db/databas.db')
  db.execute("UPDATE items SET name=?, damage=? WHERE id=?",[name,damage,id])
  redirect('/')

end

#DELETE🗑️
post('/items/:id/delete') do 
  id = params[:id].to_i
  db = connect_to_db('db/databas.db')
  db.execute("DELETE FROM items WHERE id = ?",id)
  redirect("/")
end

#FIGHT!🤺⚔️
get('/enemies/:id/fight') do
  id = params[:id].to_i
  user_id = session[:id]
  @itemsDamg = params[:itemsDamage].to_i
  
  db = connect_to_db('db/databas.db')
  @enemiesData, @itemsData=damage_data(params[:id].to_i)

  @usersInventory, @userStats=stats_inventory(session[:id].to_i)


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

  db = connect_to_db('db/databas.db')
  
  #båda returneras i funktion men jag använder endast 1 här
  @enemiesData, @itemsData=damage_data(params[:id].to_i)

  update_user_health(params[:enemyDamage].to_i,session[:id] )
  update_enemy_health(params[:itemsDamage].to_i, params[:id].to_i)
  
  redirect("/enemies/#{id}/fight")
end 

get("/game_over") do
  slim(:gameOver)
end


#SHOP🛒💵💰
get("/shop") do

  @usersData = user_data(session[:id])
  @itemsData = item_data()
  p "itemsData är: #{@itemsData}"
  @usersInventory, @userStats=stats_inventory(session[:id].to_i)

  slim(:shop)
end

post("/shop/:id/buy") do

  itemExistCheck=unique_items_checker(session[:id], params[:id].to_i)

  if itemExistCheck != nil
    # "Du äger redan detta item"

  else 
    buy_item(params[:cost].to_i, users_id = session[:id])
    get_item(session[:id], params[:id].to_i)

  end

  redirect("/shop")


end