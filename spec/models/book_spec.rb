require "rails_helper"

RSpec.describe Book, type: :model do
  let(:user) { User.create!(email_address: "owner@example.com", password: "password") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.new(title: "A Title", author: "An Author", user: user, genres: [ genre ]) }

  describe "validations" do
    it "is invalid without a title" do
      book.title = nil

      expect(book).not_to be_valid
    end

    it "is invalid without an author" do
      book.author = nil

      expect(book).not_to be_valid
    end

    it "is valid without a description" do
      book.description = nil

      expect(book).to be_valid
    end

    it "is invalid without at least one genre" do
      book.genres = []

      expect(book).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to a user" do
      book.save!

      expect(book.user).to eq(user)
    end

    it "has many genres through book_genres" do
      book.save!

      expect(book.genres).to contain_exactly(genre)
      expect(BookGenre.where(book: book, genre: genre)).to exist
    end

    it "destroys its book_genres when the book is destroyed" do
      book.save!
      book_genre = BookGenre.find_by(book: book, genre: genre)

      book.destroy

      expect(BookGenre.find_by(id: book_genre.id)).to be_nil
    end

    it "destroys its reviews when the book is destroyed" do
      book.save!
      reviewer = User.create!(email_address: "reviewer@example.com", password: "password")
      review = Review.create!(book: book, user: reviewer, rating: 4, body: "Good")

      book.destroy

      expect(Review.find_by(id: review.id)).to be_nil
    end
  end
end
