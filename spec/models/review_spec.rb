require "rails_helper"

RSpec.describe Review, type: :model do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:reviewer) { User.create!(email_address: "reviewer@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: owner, genres: [genre]) }
  describe "validations" do
    subject { Review.create!(book: book, user: reviewer, rating: 4, body: "Good read") }

    it { should validate_presence_of(:rating) }
    it { should validate_presence_of(:body) }
    it { should validate_numericality_of(:rating).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5) } 
    it { should validate_uniqueness_of(:user_id).scoped_to(:book_id).with_message("has already reviewed this book") }
  end
end