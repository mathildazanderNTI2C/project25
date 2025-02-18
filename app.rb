require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
#1. 
# - Kontrollera gems (sinatra, slim, sqlite). Kommer du behöva sessions? Troligen ej, ska endast utföra CRUD på databasen.
# - Se hur Slimfiler är organierade i mappstrukturen. Följer det REST? Hur kallar man på en slimfil i en mapp?

#2. Starta upp applikationen och inspektera koden i Chrome (högerklick>inspect). Hur ser länkarna ut? Finns de som routes i app.rb?

#3. När vi klickar på ett album vill vi även se artisten (inte bara id). Gör ett andra anrop till db och skicka med i locals.

#4. Skapa en sida där vi lägger till nya album för tex Artisten ACDC (ArtistId 1). Hitta gärna på nya namn på skivorna

#5. Skapa funktionalitet för att ta bort album

#6. Skapa funktionalitet för att uppdatera artistinformation
enable :sessions

# session[:id] = 1

get('/')  do
  slim(:index)
end

get('/profilsida') do
    slim(:profilsida)
end

get('/login') do 
    slim(:login)
end

get('/new') do 
    slim(:new)
end

post('/add_book') do
    titel = params[:titel]
    age_of_publication = params[:age_of_publication]
    author = params[:author]
    genre = params[:genre]
    review = params[:review]

    session[:data] = [titel,age_of_publication,author,genre,review]

    redirect('/') 
end