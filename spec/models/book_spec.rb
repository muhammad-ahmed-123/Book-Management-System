require "rails_helper"

RSpec.describe Book, type: :model do
  let(:user) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:valid_attributes) { { title: "A Title", author: "An Author", user: user, genres: [ genre ] } }

  describe "validations" do
    it "requires a title" do
      book = Book.new(valid_attributes.merge(title: nil))
      expect(book).not_to be_valid
      expect(book.errors[:title]).to include("can't be blank")
    end

    it "limits title length" do
      short = Book.new(valid_attributes.merge(title: "ab"))
      expect(short).not_to be_valid
      expect(short.errors[:title]).to include("is too short (minimum is 3 characters)")

      long = Book.new(valid_attributes.merge(title: "a" * 31))
      expect(long).not_to be_valid
      expect(long.errors[:title]).to include("is too long (maximum is 30 characters)")
    end

    it "requires an author" do
      book = Book.new(valid_attributes.merge(author: nil))
      expect(book).not_to be_valid
      expect(book.errors[:author]).to include("can't be blank")
    end

    it "limits author length" do
      short = Book.new(valid_attributes.merge(author: "ab"))
      expect(short).not_to be_valid
      expect(short.errors[:author]).to include("is too short (minimum is 3 characters)")

      long = Book.new(valid_attributes.merge(author: "a" * 31))
      expect(long).not_to be_valid
      expect(long.errors[:author]).to include("is too long (maximum is 30 characters)")
    end

    it "allows a nil description" do
      book = Book.new(valid_attributes.merge(description: nil))
      expect(book).to be_valid
    end

    it "limits description length" do
      book = Book.new(valid_attributes.merge(description: "a" * 501))
      expect(book).not_to be_valid
      expect(book.errors[:description]).to include("is too long (maximum is 500 characters)")
    end

    it "is invalid without at least one genre" do
      book = Book.new(valid_attributes.merge(genres: []))
      expect(book).not_to be_valid
    end
  end
end
