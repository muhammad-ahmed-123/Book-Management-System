require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires an email address" do
    user = User.new(password: "password123", password_confirmation: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "requires a unique email address" do
    user = User.new(email_address: users(:one).email_address, password: "password123", password_confirmation: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "requires a unique email address regardless of case" do
    user = User.new(email_address: users(:one).email_address.upcase, password: "password123", password_confirmation: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "requires a password of at least 8 characters on create" do
    user = User.new(email_address: "new@example.com", password: "short1", password_confirmation: "short1")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "allows updating a user without re-supplying a password" do
    user = users(:one)
    assert user.update(email_address: "one-renamed@example.com")
  end
end
