require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'


DB = SQLite3::Database.new('database.db')  # Om din databasfil heter 'database.db'
DB.results_as_hash = true
#1. 
# - Kontrollera gems (sinatra, slim, sqlite). Kommer du behöva sessions? Troligen ej, ska endast utföra CRUD på databasen.
# - Se hur Slimfiler är organierade i mappstrukturen. Följer det REST? Hur kallar man på en slimfil i en mapp?

#2. Starta upp applikationen och inspektera koden i Chrome (högerklick>inspect). Hur ser länkarna ut? Finns de som routes i app.rb?

#3. När vi klickar på ett album vill vi även se artisten (inte bara id). Gör ett andra anrop till db och skicka med i locals.

#4. Skapa en sida där vi lägger till nya album för tex Artisten ACDC (ArtistId 1). Hitta gärna på nya namn på skivorna

#5. Skapa funktionalitet för att ta bort album

#6. Skapa funktionalitet för att uppdatera artistinformation
enable :sessions

get('/') do
    # Hämta alla böcker från databasen
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM book") # Förutsätter att du har en table 'books'
    db.close
  
    # Skicka 'result' till mallen
    slim(:index, locals: { book: result }) 
end

get('/book') do
    db = SQLite3::Database.new("db/database.db")  # Uppdatera sökvägen om din databas heter annorlunda
    db.results_as_hash = true
    result = db.execute("SELECT * FROM book")   # Hämta alla böcker från tabellen 'books'
    p result  # Skriver ut resultatet i terminalen för felsökning (kan tas bort i produktionskod)
    slim(:"index", locals: {book:result})  # Skicka böckerna till Slim-sidan
    db.close  # Stäng databasen när vi är klar
end

get('/profilsida') do
    slim(:profilsida)
end

get('/showlogin') do
    slim(:login)
end

post('/register') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
    if (password == password_confirm)
      #lägg till användare
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/database.db')
      db.execute('INSERT INTO users (username, pwdigest, register) VALUES (?,?,?)', [username, password_digest, 0])
      redirect('/')
    else
      "lösenorden matchade inte!"
    end
end
  

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
  
    if BCrypt::Password.new(pwdigest) == password
      session[:"id"] = id 
      redirect('/profilsida')
    else
      "FEL LÖSEN!"
    end
end 

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
    if (password == password_confirm)
      #lägg till användare
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/database.db')
      db.execute('INSERT INTO users (username, pwdigest) VALUES (?,?)', [username, password_digest])
      redirect('/')
    else
      "lösenorden matchade inte!"
    end
end

get('/new') do 
    slim(:new)
end

post('/add_book') do
    book_name = params[:book_name]
    publishing_year = params[:publishing_year]
    author = params[:author]
    genre_id = params[:genre_id]
    reviews = params[:reviews]
    user_id = params[:user_id]  # Hämta användarens ID från formuläret
  
    db = SQLite3::Database.new("db/database.db")
    db.execute("INSERT INTO book (book_name, publishing_year, author, genre_id, reviews, user_id) VALUES (?, ?, ?, ?, ?, ?)", [book_name, publishing_year, author, genre_id, reviews, user_id])
    db.close
  
    redirect('/')
end

get('/book/:id') do
    id = params[:id].to_i
    book = DB.execute("SELECT * FROM book WHERE id = ?", id).first
    slim(:show, locals: { book: book})
end
  