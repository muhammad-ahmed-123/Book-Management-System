require "rails_helper"

RSpec.describe "Books", type: :request do
  let(:owner) { User.create!(email_address: "owner@example.com", password: "password") }
  let(:other_user) { User.create!(email_address: "other@example.com", password: "password") }
  let(:book) { Book.create!(title: "The Pragmatic Programmer", author: "David Thomas", user: owner) }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  describe "GET /books" do
    it "is visible to anonymous visitors and lists existing books" do
      book

      get books_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(book.title)
    end
  end

  describe "GET /books/:id" do
    it "is visible to anonymous visitors" do
      get book_path(book)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /books" do
    context "when the visitor is not signed in" do
      it "redirects to sign in and does not create a book" do
        expect {
          post books_path, params: { book: { title: "New Book", author: "Someone" } }
        }.not_to change(Book, :count)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the visitor is signed in" do
      it "creates a book owned by the current user" do
        sign_in(owner)

        expect {
          post books_path, params: { book: { title: "New Book", author: "Owner", description: "A great read" } }
        }.to change(Book, :count).by(1)

        expect(response).to redirect_to(Book.last)
        expect(Book.last.user).to eq(owner)
      end

      it "does not let the owning user be spoofed via params" do
        sign_in(owner)

        post books_path, params: { book: { title: "New Book", author: "Owner", user_id: other_user.id } }

        expect(Book.last.user).to eq(owner)
      end

      it "re-renders the form as unprocessable when the book is invalid" do
        sign_in(owner)

        expect {
          post books_path, params: { book: { title: "", author: "" } }
        }.not_to change(Book, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /books/:id" do
    context "when the current user owns the book" do
      it "updates the book" do
        sign_in(owner)

        patch book_path(book), params: { book: { title: "Updated Title" } }

        expect(response).to redirect_to(book_path(book))
        expect(book.reload.title).to eq("Updated Title")
      end
    end

    context "when the current user does not own the book" do
      it "does not update the book and redirects with an alert" do
        sign_in(other_user)
        original_title = book.title

        patch book_path(book), params: { book: { title: "Hacked" } }

        expect(response).to redirect_to(books_path)
        expect(book.reload.title).to eq(original_title)
      end
    end
  end

  describe "DELETE /books/:id" do
    context "when the current user owns the book" do
      it "destroys the book" do
        sign_in(owner)
        book

        expect {
          delete book_path(book)
        }.to change(Book, :count).by(-1)

        expect(response).to redirect_to(books_path)
      end
    end

    context "when the current user does not own the book" do
      it "does not destroy the book" do
        sign_in(other_user)
        book

        expect {
          delete book_path(book)
        }.not_to change(Book, :count)

        expect(response).to redirect_to(books_path)
      end
    end
  end
end
