require "rails_helper"

RSpec.describe Genre, type: :model do
  let(:genre) { Genre.new(name: "Fiction") }

  describe "validations" do
    it "is invalid without a name" do
      genre.name = nil

      expect(genre).not_to be_valid
    end

    it "is invalid with a duplicate name" do
      genre.save!
      duplicate = Genre.new(name: genre.name)

      expect(duplicate).not_to be_valid
    end

    it "is invalid with a duplicate name in a different case" do
      genre.save!
      duplicate = Genre.new(name: genre.name.upcase)

      expect(duplicate).not_to be_valid
    end
  end

  describe "#books" do
    it "returns the books associated through book_genres" do
      genre.save!
      user = User.create!(email_address: "owner@example.com", password: "password")
      book = Book.create!(title: "A Title", author: "An Author", user: user, genres: [ genre ])

      expect(genre.books).to contain_exactly(book)
    end
  end
end
