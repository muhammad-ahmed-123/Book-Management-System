require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "visiting the index while signed out shows sign in and sign up links, not sign out" do
    visit books_url

    assert_link "Sign In"
    assert_link "Sign Up"
    assert_no_button "Sign Out"
  end

  test "signing up creates an account, signs the user in, and shows a welcome notice" do
    visit new_registration_url

    fill_in "Enter your email address", with: "new_user@example.com"
    fill_in "Enter your password", with: "password123"
    fill_in "Confirm your password", with: "password123"
    click_on "Sign up"

    assert_text "Welcome! Your account has been created."
    assert_button "Sign Out"
    assert_current_path root_path
  end

  test "signing up with a duplicate email shows a validation error and does not sign in" do
    visit new_registration_url

    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "password123"
    fill_in "Confirm your password", with: "password123"
    click_on "Sign up"

    assert_text "Email address has already been taken"
    assert_no_button "Sign Out"
  end

  test "signing up with mismatched password confirmation shows a validation error" do
    visit new_registration_url

    fill_in "Enter your email address", with: "mismatch@example.com"
    fill_in "Enter your password", with: "password123"
    fill_in "Confirm your password", with: "somethingelse"
    click_on "Sign up"

    assert_text "Password confirmation doesn't match"
  end

  test "signing up with a too-short password shows a validation error" do
    visit new_registration_url

    fill_in "Enter your email address", with: "shortpw@example.com"
    fill_in "Enter your password", with: "short"
    fill_in "Confirm your password", with: "short"
    click_on "Sign up"

    assert_text "Password is too short"
  end

  test "an already authenticated visitor is redirected away from sign up" do
    sign_in_as_via_ui(@user)

    visit new_registration_url

    assert_text "You are already signed in."
    assert_current_path root_path
  end

  test "signing in with valid credentials logs the user in" do
    visit new_session_url

    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "password"
    click_on "Sign in"

    assert_button "Sign Out"
    assert_current_path root_path
  end

  test "signing in with an invalid password shows an error and does not log in" do
    visit new_session_url

    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "wrong password"
    click_on "Sign in"

    assert_text "Try another email address or password."
    assert_no_button "Sign Out"
  end

  test "signing out logs the user out and returns to the sign in page" do
    sign_in_as_via_ui(@user)

    click_button "Sign Out"

    assert_no_button "Sign Out"
    assert_current_path new_session_path

    visit books_url
    assert_link "Sign In"
  end

  test "visiting a protected page while signed out redirects to sign in" do
    visit new_book_url

    assert_current_path new_session_path
  end
end
