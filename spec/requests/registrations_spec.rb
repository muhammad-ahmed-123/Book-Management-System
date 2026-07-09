require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "POST /registration" do
    it "creates a user and signs them in with valid details" do
      params = { user: { email_address: "newuser@gmail.com", password: "Secret_123", password_confirmation: "Secret_123" } }

      expect { post registration_path, params: params }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Sign Out")
    end

    it "re-renders unprocessable entity on failure" do
      params = { user: { email_address: "invalid", password: "123" } }

      expect { post registration_path, params: params }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rescues database-level uniqueness races gracefully" do
      allow_any_instance_of(User).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

      post registration_path,
           params: { user: { email_address: "race@gmail.com", password: "Secret_123", password_confirmation: "Secret_123" } },
           headers: { "HTTP_REFERER" => new_registration_url }

      expect(response).to redirect_to(new_registration_path)
      expect(flash[:alert]).to be_present
    end
  end
end
