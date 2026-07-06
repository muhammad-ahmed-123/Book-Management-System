require "rails_helper"

RSpec.describe BookGenre, type: :model do
  let(:user) { User.create!(email_address: "owner@example.com", password: "password") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: user, genres: [ genre ]) }

  describe "validations" do
    it "is invalid without a book" do
      book_genre = BookGenre.new(book: nil, genre: genre)

      expect(book_genre).not_to be_valid
    end

    it "is invalid without a genre" do
      book_genre = BookGenre.new(book: book, genre: nil)

      expect(book_genre).not_to be_valid
    end
  end

  describe "uniqueness of the (book, genre) pair" do
    it "raises at the database level when the same pair is inserted twice" do
      expect {
        BookGenre.create!(book: book, genre: genre)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
