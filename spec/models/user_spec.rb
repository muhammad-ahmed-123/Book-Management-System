require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { User.new(email_address: "person@example.com", password: "password") }

  describe "validations" do
    it "is invalid without an email address" do
      user.email_address = nil

      expect(user).not_to be_valid
    end

    it "is invalid with a duplicate email address" do
      user.save!
      duplicate = User.new(email_address: user.email_address, password: "password")

      expect(duplicate).not_to be_valid
    end

    it "normalizes the email address by stripping whitespace and downcasing it" do
      user.email_address = "  Person@Example.com  "
      user.save!

      expect(user.reload.email_address).to eq("person@example.com")
    end

    it "is invalid with a password shorter than 8 characters" do
      user.password = "short"

      expect(user).not_to be_valid
    end

    it "is valid on an update that doesn't touch the password" do
      user.save!
      persisted = User.find(user.id)
      persisted.email_address = "changed@example.com"

      expect(persisted).to be_valid
    end
  end

  describe "#authenticate" do
    it "returns the user when the password is correct" do
      user.save!

      expect(user.authenticate("password")).to eq(user)
    end

    it "returns false when the password is incorrect" do
      user.save!

      expect(user.authenticate("wrong")).to be false
    end
  end
end
