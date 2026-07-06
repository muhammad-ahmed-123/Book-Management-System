require "rails_helper"

RSpec.describe "Reviews", type: :request do
  let(:owner) { User.create!(email_address: "owner@example.com", password: "password") }
  let(:reviewer) { User.create!(email_address: "reviewer@example.com", password: "password") }
  let(:other_user) { User.create!(email_address: "other@example.com", password: "password") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "The Pragmatic Programmer", author: "David Thomas", user: owner, genres: [ genre ]) }
  let(:review) { Review.create!(book: book, user: reviewer, rating: 5, body: "An excellent, thorough guide.") }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  describe "GET /books/:book_id/reviews/new" do
    it "redirects anonymous visitors to sign in" do
      get new_book_review_path(book)

      expect(response).to redirect_to(new_session_path)
    end

    context "when the current user owns the book" do
      it "redirects to the book with an alert instead of showing the form" do
        sign_in(owner)

        get new_book_review_path(book)

        expect(response).to redirect_to(book_path(book))
      end
    end

    context "when the current user has already reviewed the book" do
      it "redirects to the book instead of showing the form" do
        review
        sign_in(reviewer)

        get new_book_review_path(book)

        expect(response).to redirect_to(book_path(book))
      end
    end

    context "when the book_id does not correspond to an existing book" do
      it "redirects to the books list instead of raising" do
        sign_in(reviewer)

        get new_book_review_path(999_999)

        expect(response).to redirect_to(books_path)
      end
    end

    context "when the book_id is not numeric" do
      it "redirects to the books list instead of raising" do
        sign_in(reviewer)

        get "/books/abc/reviews/new"

        expect(response).to redirect_to(books_path)
      end
    end
  end

  describe "POST /books/:book_id/reviews" do
    context "when the visitor is not signed in" do
      it "redirects to sign in and does not create a review" do
        expect {
          post book_reviews_path(book), params: { review: { rating: 4, body: "Great read" } }
        }.not_to change(Review, :count)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when a non-owner signs in" do
      it "creates a review owned by the current user" do
        sign_in(reviewer)

        expect {
          post book_reviews_path(book), params: { review: { rating: 4, body: "Great read" } }
        }.to change(Review, :count).by(1)

        expect(Review.last.user).to eq(reviewer)
        expect(Review.last.book).to eq(book)
      end

      it "does not let book_id or user_id be spoofed via params" do
        other_book = Book.create!(title: "Clean Code", author: "Robert C. Martin", user: other_user, genres: [ genre ])
        sign_in(reviewer)

        post book_reviews_path(book), params: { review: { rating: 4, body: "ok", book_id: other_book.id, user_id: owner.id } }

        expect(Review.last.book).to eq(book)
        expect(Review.last.user).to eq(reviewer)
      end
    end

    context "when the current user owns the book" do
      it "does not create a review and redirects with an alert" do
        sign_in(owner)

        expect {
          post book_reviews_path(book), params: { review: { rating: 5, body: "self praise" } }
        }.not_to change(Review, :count)

        expect(response).to redirect_to(book_path(book))
        follow_redirect!
        expect(flash[:alert]).to eq("You can't review your own book.")
      end

      it "cannot be bypassed by spoofing user_id in params" do
        sign_in(owner)

        expect {
          post book_reviews_path(book), params: { review: { rating: 5, body: "sneaky", user_id: reviewer.id } }
        }.not_to change(Review, :count)
      end
    end

    context "when the current user has already reviewed the book" do
      it "does not create a second review and redirects with an alert" do
        review
        sign_in(reviewer)

        expect {
          post book_reviews_path(book), params: { review: { rating: 1, body: "again" } }
        }.not_to change(Review, :count)

        follow_redirect!
        expect(flash[:alert]).to eq("You have already reviewed this book. You can edit your existing review instead.")
      end
    end

    context "when the submitted rating is out of range" do
      it "re-renders the form as unprocessable and does not create a review" do
        sign_in(reviewer)

        expect {
          post book_reviews_path(book), params: { review: { rating: 0, body: "x" } }
        }.not_to change(Review, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the body is blank" do
      it "re-renders the form as unprocessable and does not create a review" do
        sign_in(reviewer)

        expect {
          post book_reviews_path(book), params: { review: { rating: 4, body: "" } }
        }.not_to change(Review, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /books/:book_id/reviews/:id" do
    context "when the current user wrote the review" do
      it "updates the review" do
        review
        sign_in(reviewer)

        patch book_review_path(book, review), params: { review: { rating: 3, body: "Updated opinion" } }

        expect(response).to redirect_to(book_path(book))
        expect(review.reload.rating).to eq(3)
      end
    end

    context "when the current user did not write the review" do
      it "does not update the review and redirects with an alert" do
        review
        original_rating = review.rating
        sign_in(other_user)

        patch book_review_path(book, review), params: { review: { rating: 1, body: "hijacked" } }

        expect(response).to redirect_to(book_path(book))
        follow_redirect!
        expect(flash[:alert]).to eq("You are not authorized to edit that review.")
        expect(review.reload.rating).to eq(original_rating)
      end
    end

    context "when the submitted rating is out of range" do
      it "re-renders the form as unprocessable and does not update the review" do
        review
        sign_in(reviewer)

        patch book_review_path(book, review), params: { review: { rating: 7 } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(review.reload.rating).not_to eq(7)
      end
    end
  end

  describe "GET /books/:book_id/reviews/:id/edit" do
    context "when the current user did not write the review" do
      it "redirects to the book with an alert" do
        review
        sign_in(other_user)

        get edit_book_review_path(book, review)

        expect(response).to redirect_to(book_path(book))
        follow_redirect!
        expect(flash[:alert]).to eq("You are not authorized to edit that review.")
      end
    end
  end

  describe "DELETE /books/:book_id/reviews/:id" do
    context "when the current user wrote the review" do
      it "destroys the review" do
        review

        sign_in(reviewer)

        expect {
          delete book_review_path(book, review)
        }.to change(Review, :count).by(-1)
      end
    end

    context "when the current user did not write the review" do
      it "does not destroy the review" do
        review
        sign_in(other_user)

        expect {
          delete book_review_path(book, review)
        }.not_to change(Review, :count)

        expect(response).to redirect_to(book_path(book))
      end
    end
  end

  describe "GET /books/:id" do
    it "shows reviews to anonymous visitors" do
      review

      get book_path(book)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(review.body)
    end
  end
end
