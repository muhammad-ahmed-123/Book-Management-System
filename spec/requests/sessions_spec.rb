require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { User.create!(email_address: "session@gmail.com", password: "Secret_123") }

  describe "POST /session" do
    it "signs the user in and creates a session with correct credentials" do
      expect {
        post session_path, params: { email_address: user.email_address, password: "Secret_123" }
      }.to change(Session, :count).by(1)

      expect(response).to redirect_to(root_path)
    end

    it "shows identical generic alerts for wrong passwords or invalid emails" do
      post session_path, params: { email_address: user.email_address, password: "WrongPass_1" }
      expect(flash[:alert]).to eq("Try another email address or password.")

      post session_path, params: { email_address: "nobody@gmail.com", password: "Secret_123" }
      expect(flash[:alert]).to eq("Try another email address or password.")
    end
  end

  describe "DELETE /session" do
    it "destroys the session and signs the user out" do
      post session_path, params: { email_address: user.email_address, password: "Secret_123" }

      expect { delete session_path }.to change(Session, :count).by(-1)
      expect(response).to redirect_to(new_session_path)
    end
  end
end
