require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

DB = SQLite3::Database.new('database.db')  # Om din databasfil heter 'database.db'
DB.results_as_hash = true
enable :sessions

get('/') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM book")  # Hämtar alla böcker
    db.close
    slim(:index, locals: { book: result })  # Skickar alla böcker till index-sidan
end

get('/book') do #books 
    db = SQLite3::Database.new("db/database.db")  # Uppdatera sökvägen om din databas heter annorlunda
    db.results_as_hash = true
    result = db.execute("SELECT * FROM book")   # Hämta alla böcker från tabellen 'books'
    p result  # Skriver ut resultatet i terminalen för felsökning (kan tas bort i produktionskod)
    slim(:"index", locals: {book:result})  # Skicka böckerna till Slim-sidan
    db.close  # Stäng databasen när vi är klar
end

get('/profilsida') do
    if session[:id].nil?
        redirect('/showlogin')  # Om ingen är inloggad, skicka till login
    end

    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true

    # Hämtar böcker endast för den inloggade användaren
    user_books = db.execute("SELECT * FROM book WHERE user_id = ?", session[:id])  

    slim(:profilsida, locals: { books: user_books, username: session[:username] })
end

get('/showlogin') do
    slim(:login)
end

get('/registrera') do
    slim(:registrera)
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
    if result.nil?
        "användaren finns inte"
    else 
        pwdigest = result["pwdigest"]
        id = result["id"]
    
        if BCrypt::Password.new(pwdigest) == password
        session[:id] = id 
        session[:username] = username
        redirect('/profilsida')
        else
        "FEL LÖSEN!"
        end
    end
end 

post ('/logout') do
    session[:id] = nil
    redirect('/')
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

post('/add_book') do # books 
    if session[:id].nil?
        redirect('/showlogin')  # Om ingen är inloggad, skicka till login
    end
    book_name = params[:book_name]
    publishing_year = params[:publishing_year]
    author = params[:author]
    genre_id = params[:genre_id]
    reviews = params[:reviews]
    user_id = session["id"]  # Hämta användarens ID från sessionen
  
    db = SQLite3::Database.new("db/database.db")
    db.execute("INSERT INTO book (book_name, publishing_year, author, genre_id, reviews, user_id) VALUES (?, ?, ?, ?, ?, ?)", [book_name, publishing_year, author, genre_id, reviews, user_id])
    db.close
  
    redirect('/profilsida')  # Efter bokläggning, gå till profilsidan
end


get('/book/:id') do
    db = SQLite3::Database.new("db/database.db")
    id = params[:id].to_i
    book = db.execute("SELECT * FROM book WHERE id = ?", id).first
    slim(:edit, locals: { book: book})
end
  