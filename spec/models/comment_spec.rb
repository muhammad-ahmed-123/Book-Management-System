require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:reviewer) { User.create!(email_address: "reviewer@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: owner, genres: [ genre ]) }
  let(:review) { Review.create!(book: book, user: reviewer, rating: 4, body: "Good read") }

  describe "validations" do
    it "requires a body" do
      comment = Comment.new(review: review, user: reviewer, body: nil)
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to include("can't be blank")
    end

    it "limits body length" do
      short = Comment.new(review: review, user: reviewer, body: "a")
      expect(short).not_to be_valid
      expect(short.errors[:body]).to include("is too short (minimum is 2 characters)")

      long = Comment.new(review: review, user: reviewer, body: "a" * 501)
      expect(long).not_to be_valid
      expect(long.errors[:body]).to include("is too long (maximum is 500 characters)")
    end
  end

  describe "business rules: multiple comments" do
    it "allows the same user to comment on the same review multiple times" do
      Comment.create!(review: review, user: reviewer, body: "First thought.")
      second_comment = Comment.new(review: review, user: reviewer, body: "Second thought.")
      expect(second_comment).to be_valid
    end

    it "allows a user to comment on their own review" do
      own_comment = Comment.new(review: review, user: reviewer, body: "Adding context.")
      expect(own_comment).to be_valid
    end

    it "allows a book owner to comment on a review left on their book" do
      owner_comment = Comment.new(review: review, user: owner, body: "Thanks!")
      expect(owner_comment).to be_valid
    end
  end
end
