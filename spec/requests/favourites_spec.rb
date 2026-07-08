require "rails_helper"

RSpec.describe "Favourites", type: :request do
  let(:owner) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }
  let(:fan) { User.create!(email_address: "fan@gmail.com", password: "Secret_123") }
  let(:other_user) { User.create!(email_address: "other@gmail.com", password: "Secret_123") }
  let(:genre) { Genre.create!(name: "Fiction") }
  let(:book) { Book.create!(title: "The Pragmatic Programmer", author: "David Thomas", user: owner, genres: [ genre ]) }
  let(:favourite) { Favourite.create!(book: book, user: fan) }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "Secret_123" }
  end

  describe "POST /books/:book_id/favourite" do
    context "when the visitor is not signed in" do
      it "redirects to sign in and does not create a favourite" do
        expect {
          post book_favourite_path(book)
        }.not_to change(Favourite, :count)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when a signed-in user favourites another user's book" do
      it "creates a favourite owned by the current user" do
        sign_in(fan)

        expect {
          post book_favourite_path(book)
        }.to change(Favourite, :count).by(1)

        expect(Favourite.last.user).to eq(fan)
        expect(Favourite.last.book).to eq(book)
        follow_redirect!
        expect(flash[:notice]).to eq("Book added to your favourites.")
      end

      it "does not let the book or user be spoofed via params" do
        other_book = Book.create!(title: "Clean Code", author: "Robert C. Martin", user: other_user, genres: [ genre ])
        sign_in(fan)

        post book_favourite_path(book), params: { favourite: { book_id: other_book.id, user_id: owner.id } }

        expect(Favourite.last.book).to eq(book)
        expect(Favourite.last.user).to eq(fan)
      end
    end

    context "when a user favourites their own book" do
      it "creates the favourite (no self-favourite guard)" do
        sign_in(owner)

        expect {
          post book_favourite_path(book)
        }.to change(Favourite, :count).by(1)

        expect(Favourite.last.user).to eq(owner)
        expect(Favourite.last.book).to eq(book)
      end
    end

    context "when the current user has already favourited the book" do
      it "does not create a duplicate and redirects with a friendly alert" do
        favourite
        sign_in(fan)

        expect {
          post book_favourite_path(book)
        }.not_to change(Favourite, :count)

        follow_redirect!
        expect(flash[:alert]).to eq("User have already favourited this book")
      end
    end

    context "when a uniqueness race occurs at the database level" do
      it "shows a friendly alert instead of crashing" do
        favourite
        sign_in(fan)
        allow_any_instance_of(Favourite).to receive(:save).and_raise(
          ActiveRecord::RecordNotUnique.new("UNIQUE constraint failed: favourites.user_id, favourites.book_id")
        )

        expect {
          post book_favourite_path(book)
        }.not_to change(Favourite, :count)

        follow_redirect!
        expect(flash[:alert]).to eq("You have already added this book to your favourites.")
      end
    end

    context "when the book_id does not correspond to an existing book" do
      it "redirects to the books list instead of raising" do
        sign_in(fan)

        post "/books/999999/favourite"

        expect(response).to redirect_to(books_path)
      end
    end

    context "when the book_id is not numeric" do
      it "redirects to the books list instead of raising" do
        sign_in(fan)

        post "/books/abc/favourite"

        expect(response).to redirect_to(books_path)
      end
    end

    context "when the book_id is negative, zero, or oversized" do
      it "redirects to the books list instead of raising" do
        sign_in(fan)

        [ -1, 0, 99_999_999_999_999_999_999 ].each do |bad_id|
          post "/books/#{bad_id}/favourite"

          expect(response).to redirect_to(books_path)
        end
      end
    end

    context "redirect target" do
      it "redirects back to the referring page when a referer is present" do
        sign_in(fan)

        post book_favourite_path(book), headers: { "HTTP_REFERER" => books_url }

        expect(response).to redirect_to(books_url)
      end

      it "falls back to the book page when there is no referer" do
        sign_in(fan)

        post book_favourite_path(book)

        expect(response).to redirect_to(book_path(book))
      end
    end
  end

  describe "DELETE /books/:book_id/favourite" do
    context "when the visitor is not signed in" do
      it "redirects to sign in and does not destroy a favourite" do
        favourite

        expect {
          delete book_favourite_path(book)
        }.not_to change(Favourite, :count)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the current user owns the favourite" do
      it "destroys the favourite" do
        favourite
        sign_in(fan)

        expect {
          delete book_favourite_path(book)
        }.to change(Favourite, :count).by(-1)

        follow_redirect!
        expect(flash[:notice]).to eq("Book removed from your favourites.")
      end
    end

    context "when the current user has not favourited the book" do
      it "does not destroy anything and redirects with a friendly alert" do
        favourite
        sign_in(other_user)

        expect {
          delete book_favourite_path(book)
        }.not_to change(Favourite, :count)

        follow_redirect!
        expect(flash[:alert]).to eq("You haven't favourited this book.")
      end
    end

    context "when the destroy fails" do
      it "shows a failure alert instead of crashing" do
        favourite
        sign_in(fan)
        allow_any_instance_of(Favourite).to receive(:destroy).and_return(false)

        expect {
          delete book_favourite_path(book)
        }.not_to change(Favourite, :count)

        follow_redirect!
        expect(flash[:alert]).to eq("Book couldn't be removed from your favourites. Please try again.")
      end
    end

    context "when the book_id does not correspond to an existing book" do
      it "redirects to the books list instead of raising" do
        sign_in(fan)

        delete "/books/999999/favourite"

        expect(response).to redirect_to(books_path)
      end
    end

    context "when the book_id is not numeric" do
      it "redirects to the books list instead of raising" do
        sign_in(fan)

        delete "/books/abc/favourite"

        expect(response).to redirect_to(books_path)
      end
    end

    context "when the book_id is negative, zero, or oversized" do
      it "redirects to the books list instead of raising" do
        sign_in(fan)

        [ -1, 0, 99_999_999_999_999_999_999 ].each do |bad_id|
          delete "/books/#{bad_id}/favourite"

          expect(response).to redirect_to(books_path)
        end
      end
    end
  end
end
