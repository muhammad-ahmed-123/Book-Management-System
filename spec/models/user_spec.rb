require "rails_helper"

RSpec.describe User, type: :model do
  let(:valid_attributes) { { email_address: "person@gmail.com", password: "Secret_123" } }

  describe "validations" do
    it "requires an email address" do
      user = User.new(valid_attributes.merge(email_address: nil))
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("can't be blank")
    end

    it "requires a unique email address" do
      User.create!(valid_attributes)
      duplicate = User.new(valid_attributes)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email_address]).to include("has already been taken")
    end

    it "stores a password digest when password is present" do
      user = User.create!(valid_attributes)
      expect(user.password_digest).to be_present
    end

    it "requires a password with at least 8 characters" do
      user = User.new(valid_attributes.merge(password: "Short1_"))
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
    end

    describe "email formatting" do
      it "normalizes the email address before validation" do
        user = User.new(valid_attributes)
        user.email_address = "  Person@Gmail.com  "
        user.valid?
        expect(user.email_address).to eq("person@gmail.com")
      end

      it "accepts a valid gmail address" do
        user = User.new(valid_attributes.merge(email_address: "valid.person@gmail.com"))
        expect(user).to be_valid
      end

      it "rejects a non-gmail address" do
        user = User.new(valid_attributes.merge(email_address: "person@example.com"))
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to include("must be a @gmail.com address, 1-64 characters before the @, and not numbers only")
      end

      it "rejects an address whose local part is all numbers" do
        user = User.new(valid_attributes.merge(email_address: "12345@gmail.com"))
        expect(user).not_to be_valid
      end

      it "rejects an address when the local part exceeds 64 characters" do
        long_email = "#{'a' * 65}@gmail.com"
        user = User.new(valid_attributes.merge(email_address: long_email))
        expect(user).not_to be_valid
      end
    end

    describe "custom password complexity" do
      it "rejects a password without an uppercase letter" do
        user = User.new(valid_attributes.merge(password: "secret_123"))
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("must include an uppercase letter, a lowercase letter, a number, and an underscore")
      end

      it "rejects a password without a lowercase letter" do
        user = User.new(valid_attributes.merge(password: "SECRET_123"))
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("must include an uppercase letter, a lowercase letter, a number, and an underscore")
      end

      it "rejects a password without a number" do
        user = User.new(valid_attributes.merge(password: "Secret_abc"))
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("must include an uppercase letter, a lowercase letter, a number, and an underscore")
      end

      it "rejects a password without an underscore" do
        user = User.new(valid_attributes.merge(password: "Secret1234"))
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("must include an uppercase letter, a lowercase letter, a number, and an underscore")
      end

      it "accepts a valid password" do
        user = User.new(valid_attributes.merge(password: "Valid_Pass123"))
        expect(user).to be_valid
      end
    end
  end
end
