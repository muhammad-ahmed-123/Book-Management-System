require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { User.new(email_address: "person@gmail.com", password: "Secret_123") }

  describe "validations" do
    it "is invalid without an email address" do
      user.email_address = nil

      expect(user).not_to be_valid
    end

    it "is invalid with a duplicate email address" do
      user.save!
      duplicate = User.new(email_address: user.email_address, password: "Secret_123")

      expect(duplicate).not_to be_valid
    end

    it "normalizes the email address by stripping whitespace and downcasing it" do
      user.email_address = "  Person@Gmail.com  "
      user.save!

      expect(user.reload.email_address).to eq("person@gmail.com")
    end

    it "is valid with a well-formed @gmail.com address" do
      user.email_address = "valid.person@gmail.com"

      expect(user).to be_valid
    end

    it "is invalid when the domain is not @gmail.com" do
      user.email_address = "person@example.com"

      expect(user).not_to be_valid
    end

    it "is invalid when the local part is numbers only" do
      user.email_address = "12345@gmail.com"

      expect(user).not_to be_valid
    end

    it "is invalid when the local part exceeds 64 characters" do
      user.email_address = "#{'a' * 65}@gmail.com"

      expect(user).not_to be_valid
    end

    it "is invalid with a password shorter than 8 characters" do
      user.password = "short"

      expect(user).not_to be_valid
    end

    it "is invalid on an update where the password is blank" do
      user.save!
      persisted = User.find(user.id)
      persisted.password = ""

      expect(persisted).not_to be_valid
    end

    it "is valid with a password meeting all complexity requirements" do
      user.password = "Another_Pass1"

      expect(user).to be_valid
    end

    it "is invalid when the password has no uppercase letter" do
      user.password = "secret_123"

      expect(user).not_to be_valid
    end

    it "is invalid when the password has no lowercase letter" do
      user.password = "SECRET_123"

      expect(user).not_to be_valid
    end

    it "is invalid when the password has no number" do
      user.password = "Secret_abc"

      expect(user).not_to be_valid
    end

    it "is invalid when the password has no underscore" do
      user.password = "Secret123"

      expect(user).not_to be_valid
    end
  end

  describe "associations" do
    it "destroys its favourites when the user is destroyed" do
      user.save!
      genre = Genre.create!(name: "Fiction")
      book_owner = User.create!(email_address: "owner@gmail.com", password: "Secret_123")
      book = Book.create!(title: "A Title", author: "An Author", user: book_owner, genres: [ genre ])
      favourite = Favourite.create!(book: book, user: user)

      user.destroy

      expect(Favourite.find_by(id: favourite.id)).to be_nil
    end

    it "exposes favourite_books through favourites" do
      user.save!
      genre = Genre.create!(name: "Fiction")
      book_owner = User.create!(email_address: "owner@gmail.com", password: "Secret_123")
      book = Book.create!(title: "A Title", author: "An Author", user: book_owner, genres: [ genre ])
      Favourite.create!(book: book, user: user)

      expect(user.favourite_books).to contain_exactly(book)
    end

    it "destroys its comments when the user is destroyed" do
      user.save!
      genre = Genre.create!(name: "Fiction")
      book_owner = User.create!(email_address: "owner@gmail.com", password: "Secret_123")
      book = Book.create!(title: "A Title", author: "An Author", user: book_owner, genres: [ genre ])
      review = Review.create!(book: book, user: book_owner, rating: 4, body: "Good read")
      comment = Comment.create!(review: review, user: user, body: "I agree.")

      user.destroy

      expect(Comment.find_by(id: comment.id)).to be_nil
    end
  end

  describe "#authenticate" do
    it "returns the user when the password is correct" do
      user.save!

      expect(user.authenticate("Secret_123")).to eq(user)
    end

    it "returns false when the password is incorrect" do
      user.save!

      expect(user.authenticate("wrong")).to be false
    end
  end
end
