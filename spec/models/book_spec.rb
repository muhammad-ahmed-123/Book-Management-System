require "rails_helper"

RSpec.describe Book, type: :model do
  let(:user) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:valid_attributes) { { title: "A Title", author: "An Author", user: user, genres: [genre] } }

  describe "validations" do
    subject { Book.create!(valid_attributes) }

    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(3).is_at_most(30) }
    it { should validate_presence_of(:author) }
    it { should validate_length_of(:author).is_at_least(3).is_at_most(30) }
    it { should validate_length_of(:description).is_at_most(500).allow_nil }
    it "is invalid without at least one genre" do
      book = Book.new(valid_attributes.merge(genres: []))
      expect(book).not_to be_valid
    end
  end
end