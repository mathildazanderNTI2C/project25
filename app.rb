require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'becrypt'

enable :sessions

def connect_to_db()
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    return db
end

get("/") do 
    slim(:register)
end



