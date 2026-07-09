require "rails_helper"

RSpec.describe "Favourites", type: :request do
  let(:fan) { create(:user) }
  let(:book) { create(:book) }

  describe "POST /books/:book_id/favourite" do
    context "when authenticated" do
      before { sign_in(fan) }

      it "creates a favourite for the user" do
        expect { post book_favourite_path(book) }.to change(Favourite, :count).by(1)

        expect(Favourite.last.user).to eq(fan)
        expect(Favourite.last.book).to eq(book)
      end

      it "prevents duplicate favourites" do
        create(:favourite, book: book, user: fan)

        expect { post book_favourite_path(book) }.not_to change(Favourite, :count)
        expect(flash[:alert]).to be_present
      end

      it "rescues database-level uniqueness races gracefully" do
        allow_any_instance_of(Favourite).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

        post book_favourite_path(book)

        expect(flash[:alert]).to include("already added")
      end

      it "redirects back to referer if present" do
        post book_favourite_path(book), headers: { "HTTP_REFERER" => books_url }
        expect(response).to redirect_to(books_url)
      end
    end
  end

  describe "DELETE /books/:book_id/favourite" do
    let!(:favourite) { create(:favourite, book: book, user: fan) }

    before { sign_in(fan) }

    it "destroys the favourite" do
      expect { delete book_favourite_path(book) }.to change(Favourite, :count).by(-1)
      expect(flash[:notice]).to be_present
    end

    it "handles deletion failures gracefully" do
      allow_any_instance_of(Favourite).to receive(:destroy).and_return(false)

      delete book_favourite_path(book)

      expect(flash[:alert]).to include("couldn't be removed")
    end
  end

  describe "GET /favourites" do
    it "requires authentication" do
      get favourites_path
      expect(response).to redirect_to(new_session_path)
    end

    context "when authenticated" do
      before { sign_in(fan) }

      it "lists only the current user's favourited books" do
        other_book = create(:book)
        create(:favourite, book: book, user: fan)
        create(:favourite, book: other_book) # belongs to a different user

        get favourites_path

        expect(response.body).to include(book.title)
        expect(response.body).not_to include(other_book.title)
      end

      it "displays the most recently favourited book first" do
        second_book = create(:book)
        create(:favourite, book: book, user: fan)
        travel_to(1.hour.from_now) do
          create(:favourite, book: second_book, user: fan)
        end

        get favourites_path
        expect(response.body.index(second_book.title)).to be < response.body.index(book.title)
      end
    end
  end
end