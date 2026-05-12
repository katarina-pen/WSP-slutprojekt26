require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'
require 'sinatra/flash'
require 'time'


enable :sessions

include Model


helpers do
    # Fetches the user's inventory and health stats
    #
    # @param [Integer] user_id The user's ID
    #
    # @return [Array] usersInventory List of items the user owns
    # @return [Array] userStats The user's health stats
    def stats_inventory(user_id)
      db = SQLite3::Database.new('db/databas.db')
      db.results_as_hash = true
      @usersInventory= db.execute("SELECT 
      items.name, items.damage 
      FROM users_items 
      INNER JOIN items ON users_items.items_id =items.id 
      WHERE users_id =?", user_id)
      @userStats = db.execute("SELECT health FROM users WHERE id =?", user_id)
      return @usersInventory, @userStats
    end

    # Fetches a specific enemy and all items
    #
    # @param [Integer] id The enemy's ID
    #
    # @return [Array] enemiesData The enemy's data
    # @return [Array] itemsData All items
    def damage_data(id)
      db = SQLite3::Database.new('db/databas.db')
      db.results_as_hash = true
      @enemiesData = db.execute("SELECT * FROM enemies WHERE id = ?",id)
      @itemsData = db.execute("SELECT * FROM items")
      return @enemiesData, @itemsData
    end

    # Fetches a specific user's data
    #
    # @param [Integer] user_id The user's ID
    #
    # @return [Hash] the user's data
    def user_data(user_id)
      db = SQLite3::Database.new('db/databas.db')
      db.results_as_hash = true
      @usersData = db.execute("SELECT * FROM users WHERE id = ?", user_id).first
      return @usersData
    end

    # Fetches all items from the database
    #
    # @return [Array] all items
    def item_data()
      db = SQLite3::Database.new('db/databas.db')
      db.results_as_hash = true
      @itemsData = db.execute("SELECT * FROM items")
      return @itemsData
    end
  
end

# Displays the registration form
#
get("/register") do
  slim(:register)
end

# Registers a new user and redirects to login
#
# @param [String] username The desired username
# @param [String] password The desired password
# @param [String] password_confirm The repeated password
#
# @see Model#register_user
post("/register/new") do
  username= params[:username]
  password= params[:password]
  password_confirm= params[:password_confirm]
  
  db = connect_to_db('db/databas.db')
  userExistCheck = db.execute("SELECT * FROM users WHERE username =?",username )

  if (!userExistCheck.empty?)
    flash[:user_exist] = "Denna användare finns redan! Välje ett annat användarnamn!"
    redirect("/register")

  elsif (password.length < 4 || password_confirm.length < 4 )
    flash[:short_password] = "Ditt lösenord behöver MINST 4 karaktärer"
    redirect("/register")

  elsif (password == password_confirm)
    register_user(username, password)

    redirect("/login")
  else
    flash[:not_match_password] = "Dina lösenord matchar inte!"
    redirect("/register")
    
  end

end


# Displays the login form
#
get("/login") do
  slim(:login)
end

# Attempts login with cooldown and redirects to story/1 on success
#
# @param [String] username The user's username
# @param [String] password The user's password
#
# @see Model#login_user
post("/login") do
  username= params[:username]
  password= params[:password]
  
  db = connect_to_db('db/databas.db')
  userExistCheck = db.execute("SELECT * FROM users WHERE username = ?",[username]).first

  if session[:wrong_time] == nil
        if (userExistCheck != nil)
      pwd_digest, id = login_user(username, password)

      if BCrypt::Password.new(pwd_digest)==password
        session[:id] = id 
        redirect("/story/1")
      else  
        flash[:wrong_password] = "Fel lösenord :C womp womp"
        session[:wrong_time] = Time.now
        p "#{session[:wrong_time]}"
        redirect("/login")
      end

    else 
      flash[:user_not_exist] = "användaren finns inte! 🤯"
      session[:wrong_time] = Time.now
      p "#{session[:wrong_time]}"
      redirect("/login")

    end
  elsif ((Time.now - session[:wrong_time]) < 30 )
    flash[:timeOut] = "Du har precis fått en 30 sekunder TIMEOUT!"
    sleep(30)
    redirect("/login")
  else
    if (userExistCheck != nil)
      pwd_digest, id = login_user(username, password)

      if BCrypt::Password.new(pwd_digest)==password
        session[:id] = id 
        redirect("/story/1")
      else  
        flash[:wrong_password] = "Fel lösenord :C womp womp"
        session[:wrong_time] = Time.now
        p "#{session[:wrong_time]}"
        redirect("/login")
      end

    else 
      flash[:user_not_exist] = "användaren finns inte! 🤯"
      session[:wrong_time] = Time.now
      p "#{session[:wrong_time]}"
      redirect("/login")

    end

  end

end

# Displays story page 1
#
get('/story/1') do

  db = connect_to_db('db/databas.db')
  @usersInventory, @userStats=stats_inventory(session[:id].to_i)
  
  slim(:"story/story_1")
end

# Displays story page 2
#
get('/story/2') do

  slim(:"story/story_2")

end

# Displays story page 3 with user stats
#
get('/story/3') do
  @usersInventory, @userStats=stats_inventory(session[:id].to_i)

  slim(:"story/story_3")

end

# Checks admin authorization before accessing protected routes
#
# @see Model#connect_to_db
before('/protected/*') do
 p "These are protected_methods"
    db = connect_to_db('db/databas.db')
    currentUser = session[:id]
    adminState= db.execute("SELECT adminState FROM users WHERE id =?",currentUser)

  if  currentUser == nil
    flash[:admin_error] = "Du är inte admin :( Inte välkommen >:("
    redirect('/register')

  elsif adminState[0]["adminState"] !=  1
    flash[:admin_error] = "Du är inte admin :( Inte välkommen >:("
   redirect('/register')
 end
end

# Displays the admin home page with items
#
get('/protected/home') do
  db = connect_to_db('db/databas.db')
  @enemiesData, @itemsData=damage_data(params[:enemyId])
  slim(:index) 
end

# Displays the form for creating a new item
#
get('/protected/items/new') do 
  slim(:new)
end

# Creates a new item and redirects to home
#
# @param [String] itemsName The name of the item
# @param [Integer] itemsDamg The damage of the item
# @param [Integer] itemsCost The cost of the item

#
# @see Model#create_items
post('/protected/items') do
  newItemsName = params[:itemsName]
  newItemsDamg = params[:itemsDamg]
  newItemsCost = params[:itemsCost]

  create_items(newItemsName,newItemsDamg, newItemsCost)

  redirect("/protected/home") 

end

# Displays the edit form for an item
#
# @param [Integer] :id The item's ID
#
# @see Model#edit_items
get('/protected/items/:id/edit') do
  
  db = connect_to_db('db/databas.db')
  id = params[:id].to_i
  edit_items(id)
  slim(:edit)
end

# Updates an item and redirects to home
#
# @param [Integer] :id The item's ID
# @param [String] name The new name
# @param [Integer] damage The new damage value
#
# @see Model#update_items
post('/protected/items/:id/update') do
  id = params[:id]
  name = params[:name]
  damage = params[:damage]
  update_items(name, damage, id)
  redirect('/protected/home')

end

# Deletes an item and redirects to home
#
# @param [Integer] :id The item's ID
#
# @see Model#delete_items
post('/protected/items/:id/delete') do 
  id = params[:id].to_i
  delete_items(id)
  redirect("/protected/home")
end

# Displays the fight page for a specific enemy
#
# @param [Integer] :id The enemy's ID
#
# @see Model#update_user_health
# @see Model#update_enemy_health
get('/enemies/:id') do
  id = params[:id].to_i
  user_id = session[:id]
  @enemiesData, @itemsData=damage_data(params[:id].to_i)
  @itemsDamg = @itemsData[0]["damage"]
  @usersInventory, @userStats=stats_inventory(session[:id].to_i)

   if @userStats[0]["health"] <= 0
      redirect("/game_over")
  end
  
  if @enemiesData[0]["health"] <= 0
    redirect("story/3")
  end

 

  slim(:fight)
end

# Processes an attack and updates health values
#
# @param [Integer] :id The enemy's ID
# @param [Integer] itemsDamage The damage of the selected item
# @param [Integer] enemyDamage The damage of the enemy
#
# @see Model#update_user_health
# @see Model#update_enemy_health
post("/enemies/:id/update") do
  id = params[:id].to_i
  db = connect_to_db('db/databas.db')
  @enemiesData, @itemsData=damage_data(params[:id].to_i)
  @enemiesData, @itemsData=damage_data(params[:id].to_i)
  @itemsDamg = @itemsData[0]["damage"]

  update_user_health(params[:enemyDamage].to_i,session[:id] )
  update_enemy_health(params[:itemsDamage].to_i, id)

  redirect("/enemies/#{id}")
end 

# Displays the game over page
#
get("/game_over") do
  slim(:gameOver)
end

# Displays the shop with items and user stats
#
get("/shop") do

  @usersData = user_data(session[:id])
  @itemsData = item_data()
  @usersInventory, @userStats=stats_inventory(session[:id].to_i)

  slim(:shop)
end

# Processes an item purchase
#
# @param [Integer] :id The item's ID
# @param [Integer] cost The cost of the item
#
# @see Model#unique_items_checker
# @see Model#buy_item
# @see Model#get_item
post("/shop/:id/update") do

  itemExistCheck=unique_items_checker(session[:id], params[:id].to_i)

  if itemExistCheck != nil
    # "Du äger redan detta item"

  else 
    buy_item(params[:cost].to_i, users_id = session[:id])
    get_item(session[:id], params[:id].to_i)

  end

  redirect("/shop")


end