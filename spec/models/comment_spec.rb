require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:reviewer) { User.create!(email_address: "reviewer@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: owner, genres: [ genre ]) }
  let(:review) { Review.create!(book: book, user: reviewer, rating: 4, body: "Good read") }
  let(:comment) { Comment.new(review: review, user: reviewer, body: "I agree with this.") }

  describe "validations" do
    it "is valid with a review, a user, and a body" do
      expect(comment).to be_valid
    end

    it "is invalid without a body" do
      comment.body = nil

      expect(comment).not_to be_valid
    end

    it "is invalid with a body shorter than 2 characters" do
      comment.body = "a"

      expect(comment).not_to be_valid
    end

    it "is invalid with a body longer than 500 characters" do
      comment.body = "a" * 501

      expect(comment).not_to be_valid
    end

    it "is valid with a body exactly 2 characters long" do
      comment.body = "ok"

      expect(comment).to be_valid
    end

    it "is valid with a body exactly 500 characters long" do
      comment.body = "a" * 500

      expect(comment).to be_valid
    end

    it "is valid when the same user comments on the same review more than once" do
      comment.save!
      second_comment = Comment.new(review: review, user: reviewer, body: "One more thought.")

      expect(second_comment).to be_valid
    end

    it "is valid when a user comments on their own review" do
      own_comment = Comment.new(review: review, user: reviewer, body: "Adding some context.")

      expect(own_comment).to be_valid
    end

    it "is valid when a book's owner comments on a review left on their own book" do
      owner_comment = Comment.new(review: review, user: owner, body: "Thanks for the review!")

      expect(owner_comment).to be_valid
    end
  end
end
