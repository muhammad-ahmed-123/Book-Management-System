require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "anonymous can view the sign-up form" do
    get new_registration_url
    assert_response :success
  end

  test "already authenticated user is redirected away from the sign-up form" do
    sign_in_as users(:one)

    get new_registration_url
    assert_redirected_to root_url
  end

  test "already authenticated user is redirected away from create" do
    sign_in_as users(:one)

    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "new@example.com", password: "password123", password_confirmation: "password123" } }
    end
    assert_redirected_to root_url
  end

  test "successful sign-up creates exactly one user and signs them in" do
    assert_difference("User.count", 1) do
      post registration_url, params: { user: { email_address: "new@example.com", password: "password123", password_confirmation: "password123" } }
    end

    assert_redirected_to root_url

    new_user = User.find_by(email_address: "new@example.com")
    assert_not_nil new_user

    get new_book_url
    assert_response :success
  end

  test "mismatched password confirmation re-renders with unprocessable_entity and creates no user" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "new@example.com", password: "password123", password_confirmation: "different123" } }
    end
    assert_response :unprocessable_entity
  end

  test "blank email re-renders with unprocessable_entity and creates no user" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "", password: "password123", password_confirmation: "password123" } }
    end
    assert_response :unprocessable_entity
  end

  test "duplicate email (identical case) re-renders with a friendly validation error and creates no user" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: users(:one).email_address, password: "password123", password_confirmation: "password123" } }
    end
    assert_response :unprocessable_entity
    assert_match "Email address has already been taken", response.body
  end

  test "duplicate email differing only in case is also rejected and creates no user" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: users(:one).email_address.upcase, password: "password123", password_confirmation: "password123" } }
    end
    assert_response :unprocessable_entity
    assert_match "Email address has already been taken", response.body
  end

  test "short password re-renders with unprocessable_entity and creates no user" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "new@example.com", password: "short1", password_confirmation: "short1" } }
    end
    assert_response :unprocessable_entity
  end

  test "unpermitted params like password_digest have no effect" do
    post registration_url, params: { user: { email_address: "new@example.com", password: "password123", password_confirmation: "password123", password_digest: "hacked" } }

    new_user = User.find_by(email_address: "new@example.com")
    assert_not_nil new_user
    assert_not_equal "hacked", new_user.password_digest
    assert new_user.authenticate("password123")
  end
end
