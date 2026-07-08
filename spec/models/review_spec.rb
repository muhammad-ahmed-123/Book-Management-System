require "rails_helper"

RSpec.describe Review, type: :model do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:reviewer) { User.create!(email_address: "reviewer@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: owner, genres: [ genre ]) }
  let(:review) { Review.new(book: book, user: reviewer, rating: 4, body: "Good read") }

  describe "validations" do
    it "is invalid without a rating" do
      review.rating = nil

      expect(review).not_to be_valid
    end

    it "is invalid without a body" do
      review.body = nil

      expect(review).not_to be_valid
    end

    it "is invalid with a rating below 1" do
      review.rating = 0

      expect(review).not_to be_valid
    end

    it "is invalid with a rating above 5" do
      review.rating = 6

      expect(review).not_to be_valid
    end

    it "is invalid when the same user reviews the same book twice" do
      review.save!
      duplicate = Review.new(book: book, user: reviewer, rating: 2, body: "Second thoughts")

      expect(duplicate).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to a book" do
      review.save!

      expect(review.book).to eq(book)
    end

    it "belongs to a user" do
      review.save!

      expect(review.user).to eq(reviewer)
    end
  end
end
