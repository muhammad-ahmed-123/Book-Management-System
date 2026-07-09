require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user, password: "Original_Pw1") }
  let(:token) { user.password_reset_token }

  describe "POST /passwords" do
    it "shows identical notices regardless of email existence (prevent enumeration)" do
      post passwords_path, params: { email_address: user.email_address }
      expect(flash[:notice]).to eq("Password reset instructions sent (if user with that email address exists).")

      post passwords_path, params: { email_address: "nobody@gmail.com" }
      expect(flash[:notice]).to eq("Password reset instructions sent (if user with that email address exists).")
    end
  end

  describe "PATCH /passwords/:token" do
    let!(:active_session) { user.sessions.create! }

    it "changes the password and revokes existing sessions with valid inputs" do
      patch password_path(token), params: { password: "NewValid_Pass1", password_confirmation: "NewValid_Pass1" }

      expect(response).to redirect_to(new_session_path)
      expect(user.reload.authenticate("NewValid_Pass1")).to be_truthy
      expect(Session.exists?(active_session.id)).to be false
    end

    it "rejects blank or mismatched passwords without terminating sessions" do
      patch password_path(token), params: { password: "NewValid_Pass1", password_confirmation: "Mismatch_1" }

      expect(response).to redirect_to(edit_password_path(token))
      expect(user.reload.authenticate("Original_Pw1")).to be_truthy
      expect(Session.exists?(active_session.id)).to be true
    end

    it "handles expired tokens securely" do
      travel_to(16.minutes.from_now) do
        patch password_path(token), params: { password: "NewValid_Pass1", password_confirmation: "NewValid_Pass1" }
      end

      expect(response).to redirect_to(new_password_path)
      expect(user.reload.authenticate("Original_Pw1")).to be_truthy
    end

    it "redirects gracefully if the token is entirely invalid" do
      patch password_path("bogus-token"), params: { password: "New", password_confirmation: "New" }
      expect(response).to redirect_to(new_password_path)
    end
  end
end