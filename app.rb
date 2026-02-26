require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'


get('/') do
  slim(:index) 
end

get('/fight') do
  slim(:fight)
end