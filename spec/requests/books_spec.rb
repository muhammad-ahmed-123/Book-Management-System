require "rails_helper"

RSpec.describe "Books", type: :request do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:other_user) { User.create!(email_address: "other@gmail.com", password: "Secret_123") }
  let(:fiction) { Genre.create!(name: "Fiction") }
  let(:mystery) { Genre.create!(name: "Mystery") }
  let(:book) { Book.create!(title: "The Pragmatic Programmer", author: "David Thomas", user: owner, genres: [ fiction ]) }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "Secret_123" }
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

    it "displays the book's genres" do
      get book_path(book)

      expect(response.body).to include(fiction.name)
    end

    context "when the id does not correspond to an existing book" do
      it "redirects to the books list instead of raising" do
        get book_path(999_999)

        expect(response).to redirect_to(books_path)
      end
    end

    context "when the id is not numeric" do
      it "redirects to the books list instead of raising" do
        get "/books/abc"

        expect(response).to redirect_to(books_path)
      end
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
          post books_path, params: { book: { title: "New Book", author: "Owner", description: "A great read", genre_ids: [ fiction.id ] } }
        }.to change(Book, :count).by(1)

        expect(response).to redirect_to(Book.last)
        expect(Book.last.user).to eq(owner)
      end

      it "does not let the owning user be spoofed via params" do
        sign_in(owner)

        post books_path, params: { book: { title: "New Book", author: "Owner", user_id: other_user.id, genre_ids: [ fiction.id ] } }

        expect(Book.last.user).to eq(owner)
      end

      it "re-renders the form as unprocessable when the book is invalid" do
        sign_in(owner)

        expect {
          post books_path, params: { book: { title: "", author: "" } }
        }.not_to change(Book, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "assigns the selected genres to the created book" do
        sign_in(owner)

        post books_path, params: { book: { title: "New Book", author: "Owner", genre_ids: [ fiction.id, mystery.id ] } }

        expect(Book.last.genres).to contain_exactly(fiction, mystery)
      end

      context "when no genre is selected" do
        it "does not create a book" do
          expect {
            sign_in(owner)
            post books_path, params: { book: { title: "New Book", author: "Owner", genre_ids: [ "" ] } }
          }.not_to change(Book, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
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

      it "leaves existing genres untouched when genre_ids is not submitted" do
        sign_in(owner)

        patch book_path(book), params: { book: { title: "Updated Title" } }

        expect(book.reload.genres).to contain_exactly(fiction)
      end

      it "swaps the selected genres when new genre_ids are submitted" do
        sign_in(owner)

        patch book_path(book), params: { book: { genre_ids: [ mystery.id ] } }

        expect(response).to redirect_to(book_path(book))
        expect(book.reload.genres).to contain_exactly(mystery)
      end

      context "when every genre is unchecked" do
        it "rejects the update and leaves the title and genres unchanged" do
          book
          original_title = book.title
          original_genre_ids = book.genre_ids.sort

          sign_in(owner)
          patch book_path(book), params: { book: { title: "Should not save", genre_ids: [ "" ] } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(book.reload.title).to eq(original_title)
          expect(book.genre_ids.sort).to eq(original_genre_ids)
        end
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
