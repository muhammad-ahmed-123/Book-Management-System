require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { User.create!(email_address: "owner@gmail.com", password: "Original_Pw1") }
  let(:token) { user.password_reset_token }

  describe "PATCH /passwords/:token" do
    context "when the submitted password is blank" do
      it "does not change the password and does not destroy other sessions" do
        session = user.sessions.create!
        digest_before = user.password_digest

        patch password_path(token), params: { password: "", password_confirmation: "" }

        expect(response).to redirect_to(edit_password_path(token))
        expect(user.reload.password_digest).to eq(digest_before)
        expect(user.authenticate("Original_Pw1")).to eq(user)
        expect(Session.exists?(session.id)).to be true
      end
    end

    context "when the submitted password is too short" do
      it "does not change the password" do
        digest_before = user.password_digest

        patch password_path(token), params: { password: "Short_1", password_confirmation: "Short_1" }

        expect(response).to redirect_to(edit_password_path(token))
        expect(user.reload.password_digest).to eq(digest_before)
      end
    end

    context "when the confirmation does not match" do
      it "does not change the password" do
        digest_before = user.password_digest

        patch password_path(token), params: { password: "NewValid_Pass1", password_confirmation: "Different_Pass2" }

        expect(response).to redirect_to(edit_password_path(token))
        expect(user.reload.password_digest).to eq(digest_before)
      end
    end

    context "when a valid new password is submitted" do
      it "changes the password and destroys all existing sessions" do
        session = user.sessions.create!
        digest_before = user.password_digest

        patch password_path(token), params: { password: "NewValid_Pass1", password_confirmation: "NewValid_Pass1" }

        expect(response).to redirect_to(new_session_path)
        expect(user.reload.password_digest).not_to eq(digest_before)
        expect(user.authenticate("NewValid_Pass1")).to eq(user)
        expect(Session.exists?(session.id)).to be false
      end
    end

    context "when the token is invalid" do
      it "redirects to the new password request page instead of raising" do
        patch password_path("bogus-token"), params: { password: "NewValid_Pass1", password_confirmation: "NewValid_Pass1" }

        expect(response).to redirect_to(new_password_path)
      end
    end
  end
end
