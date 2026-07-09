module RequestHelpers
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "Secret_123" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
