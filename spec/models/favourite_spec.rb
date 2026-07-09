require "rails_helper"

RSpec.describe Favourite, type: :model do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:other_user) { User.create!(email_address: "other@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: owner, genres: [ genre ]) }

  describe "validations" do
    it "requires a unique favourite per user per book" do
      Favourite.create!(book: book, user: other_user)
      duplicate = Favourite.new(book: book, user: other_user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("have already favourited this book")
    end
  end

  describe "business rules" do
    it "allows a user to favourite their own book" do
      own_favourite = Favourite.new(book: book, user: owner)
      expect(own_favourite).to be_valid
    end
  end
end
