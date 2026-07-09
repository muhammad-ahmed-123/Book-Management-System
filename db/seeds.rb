# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

[
  "Fiction", "Non-fiction", "Mystery", "Sci-Fi", "Fantasy",
  "Biography", "Self-Help", "History", "Romance", "Horror",
  "Poetry", "Science"
].each do |genre_name|
  Genre.find_or_create_by!(name: genre_name)
end

demo_users = (1..5).map do |n|
  User.find_or_create_by!(email_address: "demo.reader#{n}@gmail.com") do |user|
    user.password = "Demo_Pass1"
  end
end

books = [
  [ "1984", "George Orwell", %w[ Fiction Sci-Fi ] ],
  [ "Animal Farm", "George Orwell", %w[ Fiction ] ],
  [ "Brave New World", "Aldous Huxley", %w[ Sci-Fi Fiction ] ],
  [ "Fahrenheit 451", "Ray Bradbury", %w[ Sci-Fi ] ],
  [ "The Great Gatsby", "F. Scott Fitzgerald", %w[ Fiction Romance ] ],
  [ "To Kill a Mockingbird", "Harper Lee", %w[ Fiction History ] ],
  [ "Pride and Prejudice", "Jane Austen", %w[ Romance Fiction ] ],
  [ "Moby Dick", "Herman Melville", %w[ Fiction ] ],
  [ "War and Peace", "Leo Tolstoy", %w[ Fiction History ] ],
  [ "Crime and Punishment", "Fyodor Dostoevsky", %w[ Mystery Fiction ] ],
  [ "The Catcher in the Rye", "J.D. Salinger", %w[ Fiction ] ],
  [ "Lord of the Flies", "William Golding", %w[ Fiction ] ],
  [ "The Hobbit", "J.R.R. Tolkien", %w[ Fantasy ] ],
  [ "The Fellowship of the Ring", "J.R.R. Tolkien", %w[ Fantasy ] ],
  [ "A Game of Thrones", "George R.R. Martin", %w[ Fantasy ] ],
  [ "Harry Potter", "J.K. Rowling", %w[ Fantasy ] ],
  [ "The Da Vinci Code", "Dan Brown", %w[ Mystery ] ],
  [ "Gone Girl", "Gillian Flynn", %w[ Mystery ] ],
  [ "Sherlock Holmes", "Arthur Conan Doyle", %w[ Mystery ] ],
  [ "And Then There Were None", "Agatha Christie", %w[ Mystery ] ],
  [ "Murder on the Orient Express", "Agatha Christie", %w[ Mystery ] ],
  [ "Dune", "Frank Herbert", %w[ Sci-Fi ] ],
  [ "Ender's Game", "Orson Scott Card", %w[ Sci-Fi ] ],
  [ "The Martian", "Andy Weir", %w[ Sci-Fi ] ],
  [ "Neuromancer", "William Gibson", %w[ Sci-Fi ] ],
  [ "I, Robot", "Isaac Asimov", %w[ Sci-Fi ] ],
  [ "Foundation", "Isaac Asimov", %w[ Sci-Fi ] ],
  [ "The Shining", "Stephen King", %w[ Horror ] ],
  [ "Dracula", "Bram Stoker", %w[ Horror ] ],
  [ "Frankenstein", "Mary Shelley", %w[ Horror ] ],
  [ "Carrie", "Stephen King", %w[ Horror ] ],
  [ "The Exorcist", "William Peter Blatty", %w[ Horror ] ],
  [ "Sapiens", "Yuval Noah Harari", %w[ Non-fiction History ] ],
  [ "Educated", "Tara Westover", %w[ Biography Non-fiction ] ],
  [ "Becoming", "Michelle Obama", %w[ Biography ] ],
  [ "Steve Jobs", "Walter Isaacson", %w[ Biography ] ],
  [ "Long Walk to Freedom", "Nelson Mandela", %w[ Biography History ] ],
  [ "The 48 Laws of Power", "Robert Greene", %w[ Self-Help History ] ],
  [ "The Art of Seduction", "Robert Greene", %w[ Self-Help Biography ] ],
  [ "Rich Dad Poor Dad", "Robert Kiyosaki", %w[ Self-Help ] ],
  [ "Atomic Habits", "James Clear", %w[ Self-Help ] ],
  [ "The Lean Startup", "Eric Ries", %w[ Self-Help Non-fiction ] ],
  [ "Thinking, Fast and Slow", "Daniel Kahneman", %w[ Self-Help Science ] ],
  [ "The Selfish Gene", "Richard Dawkins", %w[ Science ] ],
  [ "A Brief History of Time", "Stephen Hawking", %w[ Science ] ],
  [ "Cosmos", "Carl Sagan", %w[ Science ] ],
  [ "The Origin of Species", "Charles Darwin", %w[ Science History ] ],
  [ "Guns, Germs, and Steel", "Jared Diamond", %w[ History Science ] ],
  [ "The Silk Roads", "Peter Frankopan", %w[ History ] ],
  [ "Leaves of Grass", "Walt Whitman", %w[ Poetry ] ]
]

books.each_with_index do |(title, author, genre_names), index|
  owner = demo_users[index % demo_users.size]

  Book.find_or_create_by!(title: title, author: author) do |book|
    book.user = owner
    book.description = "A #{genre_names.first.downcase} book by #{author}."
    book.genres = Genre.where(name: genre_names)
  end
end
