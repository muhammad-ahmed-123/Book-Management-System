require "rails_helper"

RSpec.describe BookGenre, type: :model do
  let(:user) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: user, genres: [ genre ]) }

  describe "uniqueness of the (book, genre) pair" do
    it "raises at the database level when the same pair is inserted twice" do
      expect {
        BookGenre.create!(book: book, genre: genre)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
