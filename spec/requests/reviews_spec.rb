require "rails_helper"

RSpec.describe "Reviews", type: :request do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:reviewer) { User.create!(email_address: "reviewer@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "A Title", author: "An Author", user: owner, genres: [ genre ]) }
  let(:review) { Review.create!(book: book, user: reviewer, rating: 4, body: "Great") }

  describe "POST /books/:book_id/reviews" do
    context "when authenticated" do
      before { sign_in(reviewer) }

      it "creates a review" do
        params = { review: { rating: 4, body: "Great read" } }
        expect { post book_reviews_path(book), params: params }.to change(Review, :count).by(1)
        expect(Review.last.user).to eq(reviewer)
      end

      it "prevents users from reviewing their own books" do
        sign_in(owner)

        expect {
          post book_reviews_path(book), params: { review: { rating: 5, body: "Self praise" } }
        }.not_to change(Review, :count)

        expect(flash[:alert]).to include("can't review your own book")
      end

      it "prevents duplicate reviews from the same user" do
        review # Create existing review
        expect {
          post book_reviews_path(book), params: { review: { rating: 2, body: "Again" } }
        }.not_to change(Review, :count)

        expect(flash[:alert]).to be_present
      end

      it "neutralizes array injections in scalar params" do
        post book_reviews_path(book), params: { review: { rating: [ "1", "2" ], body: "x" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /books/:book_id/reviews/:id" do
    let!(:existing_review) { review }

    it "updates the review if authored by the user" do
      sign_in(reviewer)
      patch book_review_path(book, existing_review), params: { review: { rating: 3 } }

      expect(existing_review.reload.rating).to eq(3)
    end

    it "rejects updates if unauthorized" do
      sign_in(User.create!(email_address: "random@gmail.com", password: "Secret_123"))
      patch book_review_path(book, existing_review), params: { review: { rating: 1 } }

      expect(flash[:alert]).to eq("You are not authorized to edit that review.")
      expect(existing_review.reload.rating).not_to eq(1)
    end
  end

  describe "DELETE /books/:book_id/reviews/:id" do
    let!(:target_review) { review }

    it "destroys the review if authorized" do
      sign_in(reviewer)
      expect { delete book_review_path(book, target_review) }.to change(Review, :count).by(-1)
    end
  end
end
