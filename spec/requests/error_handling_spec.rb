require "rails_helper"

RSpec.describe "Unexpected errors", type: :request do
  describe "an exception with no specific rescue_from handler" do
    context "when a referer is present" do
      it "redirects back to it with a friendly alert instead of crashing" do
        allow(Book).to receive(:includes).and_raise(StandardError, "boom")

        get books_path, headers: { "HTTP_REFERER" => new_session_url }

        expect(response).to redirect_to(new_session_url)

        follow_redirect!
        expect(flash[:alert]).to eq("Something went wrong. Please try again.")
      end
    end

    context "when there is no referer to fall back on" do
      it "renders the generic error page instead of crashing or redirect-looping" do
        allow(Book).to receive(:includes).and_raise(StandardError, "boom")

        get books_path

        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to include("We're sorry, but something went wrong.")
      end
    end
  end

  describe "exceptions that already have a specific handler" do
    it "still uses the specific message instead of the generic catch-all" do
      get book_path(999_999)

      expect(response).to redirect_to(books_path)
      follow_redirect!
      expect(flash[:alert]).to eq("That book doesn't exist.")
    end
  end
end
