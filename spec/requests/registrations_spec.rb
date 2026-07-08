require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "POST /registration" do
    context "with valid details" do
      it "creates a user and signs them in" do
        expect {
          post registration_path, params: { user: { email_address: "new.person@gmail.com", password: "Secret_123", password_confirmation: "Secret_123" } }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Sign Out")
      end
    end

    context "with invalid details" do
      it "does not create a user and re-renders the form" do
        expect {
          post registration_path, params: { user: { email_address: "not-a-gmail@example.com", password: "weak", password_confirmation: "weak" } }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when a uniqueness race occurs at the database level" do
      it "shows a failure alert instead of crashing" do
        allow_any_instance_of(User).to receive(:save).and_raise(
          ActiveRecord::RecordNotUnique.new("UNIQUE constraint failed: users.email_address")
        )

        expect {
          post registration_path,
            params: { user: { email_address: "race@gmail.com", password: "Secret_123", password_confirmation: "Secret_123" } },
            headers: { "HTTP_REFERER" => new_registration_url }
        }.not_to change(User, :count)

        expect(response).to redirect_to(new_registration_path)
        follow_redirect!
        expect(flash[:alert]).to eq("Something went wrong and your change couldn't be saved. Please try again.")
      end
    end
  end
end
