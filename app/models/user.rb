class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :books, dependent: :destroy
  has_many :reviews, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address,
    presence: true,
    uniqueness: true,
    format: {
      with: /\A(?=[^@]*[A-Za-z])[A-Za-z0-9._%+-]{1,64}@gmail\.com\z/,
      message: "must be a @gmail.com address, 1-64 characters before the @, and not numbers only"
    }

  validates :password,
    length: { minimum: 8 },
    format: {
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*_).+\z/,
      message: "must include an uppercase letter, a lowercase letter, a number, and an underscore"
    }
end
