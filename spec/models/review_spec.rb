require "rails_helper"

RSpec.describe Review, type: :model do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:reviewer) { User.create!(email_address: "reviewer@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: owner, genres: [ genre ]) }

  describe "validations" do
    it "requires a rating" do
      review = Review.new(book: book, user: reviewer, rating: nil, body: "Good read")
      expect(review).not_to be_valid
      expect(review.errors[:rating]).to include("can't be blank")
    end

    it "requires a body" do
      review = Review.new(book: book, user: reviewer, rating: 4, body: nil)
      expect(review).not_to be_valid
      expect(review.errors[:body]).to include("can't be blank")
    end

    it "requires rating to be between 1 and 5" do
      invalid = Review.new(book: book, user: reviewer, rating: 0, body: "Good read")
      expect(invalid).not_to be_valid
      expect(invalid.errors[:rating]).to include("must be between 1 and 5")
    end

    it "prevents a user from reviewing the same book twice" do
      Review.create!(book: book, user: reviewer, rating: 4, body: "Good read")
      duplicate = Review.new(book: book, user: reviewer, rating: 5, body: "Another read")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("have already reviewed this book")
    end
  end
end
