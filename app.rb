require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

DB = SQLite3::Database.new('db/database.db')  # Om din databasfil heter 'database.db'
DB.results_as_hash = true

enable:sessions
secure_paths = ["/profilsida"]
before (secure_paths) do
    if session[:id] == nil
        redirect('/')
    end
end

get('/') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM book")  # Hämtar alla böcker
    db.close
    slim(:index, locals: {book: result, admin:checkAdmin(session[:id])})  # Skickar alla böcker till index-sidan
end

get('/books') do
    db = SQLite3::Database.new("db/database.db")  # Uppdatera sökvägen om din databas heter annorlunda
    db.results_as_hash = true
    result = db.execute("SELECT * FROM book")   # Hämta alla böcker från tabellen 'books'
    p result  # Skriver ut resultatet i terminalen för felsökning (kan tas bort i produktionskod)
    slim(:"index", locals: {book: result})  # Skicka böckerna till Slim-sidan
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
    slim(:"user/login")
end

get('/registrera') do
    slim(:"user/registrera")
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

get('/new') do # vill ändra till get books/new men sidan krashar då?
    slim(:"books/new")
end

post('/books') do 
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

get('/books/:id') do
    db = SQLite3::Database.new("db/database.db")
    id = params[:id].to_i
    book = db.execute("SELECT * FROM book WHERE id = ?", id).first
    slim(:"books/edit_book", locals: { book: book})
end

get('/edit_book/:id') do
    # Kontrollera om användaren är inloggad
    if session[:id].nil?
        redirect('/showlogin')  # Om ingen är inloggad, skicka till login
    end

    book_id = params[:id].to_i
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true

    # Hämta boken från databasen
    book = db.execute("SELECT * FROM book WHERE id = ?", book_id).first

    # Kontrollera om den inloggade användaren är ägaren av boken
    if book && book["user_id"] == session[:id]
        slim(:"books/edit_book", locals: { book: book })  # Skicka boken till redigeringssidan
    else
        redirect('/error')  # Om användaren inte äger boken, skicka till fel-sidan
    end
end

post('/update_book/:id') do
    book_id = params[:id].to_i
    
    # Hämta boken från databasen
    book = DB.execute("SELECT * FROM book WHERE id = ?", [book_id])
    
    if book.nil?
      return "Boken hittades inte"
    end
  
    book_name = params[:book_name]
    publishing_year = params[:publishing_year]
    author = params[:author]
    genre_id = params[:genre_id]
    reviews = params[:reviews].to_i
  
    DB.execute("UPDATE book SET book_name = ?, publishing_year = ?, author = ?, genre_id = ?, reviews = ? WHERE id = ?",
               [book_name, publishing_year, author, genre_id, reviews, book_id])
  
    redirect "/"
  end


post('/delete_book/:id') do
  DB.results_as_hash = true  # Gör så att vi kan använda bok["user_id"]
  book_id = params[:id].to_i
  p checkAdmin(session[:id])[0]
  book = DB.execute("SELECT * FROM book WHERE id = ?", [book_id]).first
  if book && book["user_id"] == session[:id]
    DB.execute("DELETE FROM book WHERE id = ?", [book_id])
    puts "Bok med ID #{book_id} raderades"
  elsif checkAdmin(session[:id])[0] != nil
    DB.execute("DELETE FROM book WHERE id = ?", [book_id])
    puts "Bok med ID #{book_id} raderades"
    redirect ('/')
  else
    puts "Ingen rätt att radera eller bok hittades inte"
  end

  redirect ('/profilsida')
end

def checkAdmin(id)
    return DB.execute('SELECT admin FROM users WHERE id = ?', [id])
end

def authorized_to_modify?(book_id, user_id)
  book = DB.execute("SELECT * FROM book WHERE id = ?", [book_id]).first
  return false if book.nil?

  is_owner = book["user_id"] == user_id
  is_admin = checkAdmin(user_id).first["admin"] == 1

  is_owner || is_admin
end
