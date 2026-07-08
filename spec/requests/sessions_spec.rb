require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { User.create!(email_address: "owner@gmail.com", password: "Secret_123") }

  describe "POST /session" do
    context "with correct credentials" do
      it "signs the user in and creates a session" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "Secret_123" }
        }.to change(Session, :count).by(1)

        expect(response).to redirect_to(root_path)
      end
    end

    context "with the wrong password" do
      it "does not sign in and shows a generic alert" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "WrongPass_1" }
        }.not_to change(Session, :count)

        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(flash[:alert]).to eq("Try another email address or password.")
      end
    end

    context "with an email address that does not exist" do
      it "shows the identical generic alert, not a different message" do
        expect {
          post session_path, params: { email_address: "nobody@gmail.com", password: "Secret_123" }
        }.not_to change(Session, :count)

        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(flash[:alert]).to eq("Try another email address or password.")
      end
    end
  end

  describe "DELETE /session" do
    it "destroys the session and signs the user out" do
      user
      post session_path, params: { email_address: user.email_address, password: "Secret_123" }

      expect {
        delete session_path
      }.to change(Session, :count).by(-1)

      expect(response).to redirect_to(new_session_path)
    end
  end
end
