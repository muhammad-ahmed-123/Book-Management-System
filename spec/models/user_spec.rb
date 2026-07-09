require "rails_helper"

RSpec.describe User, type: :model do
  let(:valid_attributes) { { email_address: "person@gmail.com", password: "Secret_123" } }
  let(:user) { User.new(valid_attributes) }

  describe "validations" do
    subject { User.create!(valid_attributes) }

    it { should validate_presence_of(:email_address) }
    it { should validate_uniqueness_of(:email_address).case_insensitive }
    it { should have_secure_password }
    it { should validate_length_of(:password).is_at_least(8) }

    describe "email formatting" do
      it "normalizes the email address before validation" do
        user.email_address = "  Person@Gmail.com  "
        user.valid?
        expect(user.email_address).to eq("person@gmail.com")
      end

      it { should allow_value("valid.person@gmail.com").for(:email_address) }
      it { should_not allow_value("person@example.com").for(:email_address).with_message(/must be a gmail address/i) }
      it { should_not allow_value("12345@gmail.com").for(:email_address) }
      
      it "is invalid when the local part exceeds 64 characters" do
        long_email = "#{'a' * 65}@gmail.com"
        should_not allow_value(long_email).for(:email_address)
      end
    end

    describe "custom password complexity" do
      it { should_not allow_value("secret_123").for(:password).with_message(/must include an uppercase letter/) }
      it { should_not allow_value("SECRET_123").for(:password).with_message(/must include a lowercase letter/) }
      it { should_not allow_value("Secret_abc").for(:password).with_message(/must include a number/) }
      it { should_not allow_value("Secret1234").for(:password).with_message(/must include an underscore/) }
      it { should allow_value("Valid_Pass123").for(:password) }
    end
  end
end