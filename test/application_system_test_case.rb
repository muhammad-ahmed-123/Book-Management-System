require "test_helper"

Capybara.register_driver :headless_chrome_no_password_manager do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--disable-gpu")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-search-engine-choice-screen")
  # Our specs repeatedly sign in with the same fixture credentials; without this,
  # Chrome's save/update-password prompt intermittently steals focus mid-test and
  # silently swallows subsequent fill_in keystrokes.
  options.add_preference("credentials_enable_service", false)
  options.add_preference("profile.password_manager_enabled", false)
  options.add_preference("profile.password_manager_leak_detection", false)

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :headless_chrome_no_password_manager, screen_size: [ 1400, 1400 ]

  Capybara.default_max_wait_time = 5

  def sign_in_as_via_ui(user)
    visit new_session_url
    fill_in "Enter your email address", with: user.email_address
    fill_in "Enter your password", with: "password"
    click_on "Sign in"

    # Turbo Drive navigates asynchronously, so wait for a post-login element
    # before returning — otherwise callers can race ahead of the redirect.
    assert_button "Sign Out"
  end

  # Bypasses the browser's native "required" popup so a deliberately blank
  # field actually reaches the server and exercises its validation.
  def disable_html5_validation
    execute_script("document.querySelectorAll('[required]').forEach(el => el.removeAttribute('required'))")
  end
end
