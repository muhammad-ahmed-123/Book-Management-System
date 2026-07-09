require "rails_helper"

RSpec.describe "Books", type: :request do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:other_user) { User.create!(email_address: "other@gmail.com", password: "Secret_123") }
  let(:fiction) { Genre.create!(name: "Fiction") }
  let(:mystery) { Genre.create!(name: "Mystery") }
  let(:book) do
    Book.create!(title: "A Title", author: "An Author", user: owner, genres: [ fiction ])
  end

  describe "GET /books" do
    let!(:existing_book) { book }

    it "is visible to anonymous visitors and lists existing books" do
      get books_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(existing_book.title)
    end

    context "when the visitor is not signed in" do
      it "does not show a favourite toggle button" do
        get books_path
        expect(response.body).not_to include("Favourites")
      end
    end

    context "when the visitor is signed in" do
      before { sign_in(other_user) }

      it "shows an Add to Favourites button when not favourited" do
        get books_path
        expect(response.body).to include("Add to Favourites")
      end

      it "shows a Remove from Favourites button when favourited" do
        Favourite.create!(book: existing_book, user: other_user)
        get books_path
        expect(response.body).to include("Remove from Favourites")
      end
    end
  end

  describe "GET /books/:id" do
    it "is visible to anonymous visitors and displays genres" do
      get book_path(book)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(fiction.name)
    end

    it "never shows a favourite toggle button on the detail page" do
      Favourite.create!(book: book, user: other_user)
      sign_in(other_user)

      get book_path(book)

      expect(response.body).not_to include("Add to Favourites")
      expect(response.body).not_to include("Remove from Favourites")
    end

    context "when the record does not exist" do
      it "redirects to the books list" do
        get book_path("invalid_id")
        expect(response).to redirect_to(books_path)
      end
    end
  end

  describe "POST /books" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        post books_path, params: { book: { title: "New Book" } }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in(owner) }

      it "creates a book and assigns genres" do
        params = {
          book: {
            title: "New Book",
            author: "New Author",
            description: "A new book",
            genre_ids: [ fiction.id, mystery.id ]
          }
        }

        expect { post books_path, params: params }.to change(Book, :count).by(1)

        expect(response).to redirect_to(Book.last)
        expect(Book.last.genres).to contain_exactly(fiction, mystery)
        expect(Book.last.user).to eq(owner)
      end

      it "ignores spoofed user_ids via strong params" do
        params = {
          book: {
            title: "New Book",
            author: "New Author",
            description: "A new book",
            user_id: other_user.id,
            genre_ids: [ fiction.id ]
          }
        }
        post books_path, params: params
        expect(Book.last.user).to eq(owner)
      end

      it "re-renders unprocessable entity on validation failure" do
        post books_path, params: { book: { title: "", genre_ids: [] } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "deduplicates submitted genres" do
        params = {
          book: {
            title: "New Book",
            author: "New Author",
            description: "A new book",
            genre_ids: [ fiction.id, fiction.id ]
          }
        }
        post books_path, params: params
        expect(Book.last.genres).to contain_exactly(fiction)
      end
    end
  end

  describe "PATCH /books/:id" do
    context "when the current user owns the book" do
      before { sign_in(owner) }

      it "updates the book and leaves unsubmitted genres untouched" do
        patch book_path(book), params: { book: { title: "Updated Title" } }

        expect(response).to redirect_to(book_path(book))
        expect(book.reload.title).to eq("Updated Title")
        expect(book.genres).to contain_exactly(fiction)
      end

      it "swaps genres when new genre_ids are submitted" do
        patch book_path(book), params: { book: { genre_ids: [ mystery.id ] } }
        expect(book.reload.genres).to contain_exactly(mystery)
      end

      it "rejects the update if every genre is unchecked" do
        patch book_path(book), params: { book: { title: "Hacked", genre_ids: [ "" ] } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(book.reload.title).not_to eq("Hacked")
      end
    end

    context "when the current user is unauthorized" do
      it "redirects without updating" do
        sign_in(other_user)

        patch book_path(book), params: { book: { title: "Hacked" } }

        expect(response).to redirect_to(books_path)
        expect(book.reload.title).not_to eq("Hacked")
      end
    end
  end

  describe "DELETE /books/:id" do
    let!(:target_book) { Book.create!(title: "Target Book", author: "Author", user: owner, genres: [ fiction ]) }

    it "destroys the book if authorized" do
      sign_in(owner)

      expect { delete book_path(target_book) }.to change(Book, :count).by(-1)
      expect(response).to redirect_to(books_path)
    end

    it "prevents destruction if unauthorized" do
      sign_in(other_user)

      expect { delete book_path(target_book) }.not_to change(Book, :count)
      expect(response).to redirect_to(books_path)
    end

    it "handles deletion failures gracefully" do
      sign_in(owner)
      allow_any_instance_of(Book).to receive(:destroy).and_return(false)

      delete book_path(target_book)

      expect(response).to redirect_to(book_path(target_book))
      expect(flash[:alert]).to be_present
    end
  end
end
