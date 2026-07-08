require "rails_helper"

RSpec.describe Favourite, type: :model do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:other_user) { User.create!(email_address: "other@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: owner, genres: [ genre ]) }
  let(:favourite) { Favourite.new(book: book, user: other_user) }

  describe "validations" do
    it "is valid with a book and a user" do
      expect(favourite).to be_valid
    end

    it "is invalid when the same user favourites the same book twice" do
      favourite.save!
      duplicate = Favourite.new(book: book, user: other_user)

      expect(duplicate).not_to be_valid
    end

    it "is valid when a user favourites their own book" do
      own_favourite = Favourite.new(book: book, user: owner)

      expect(own_favourite).to be_valid
    end

    it "raises at the database level when the uniqueness validation is bypassed" do
      favourite.save!
      duplicate = Favourite.new(book: book, user: other_user)

      expect {
        duplicate.save!(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
