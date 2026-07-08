class Favourite < ApplicationRecord
  belongs_to :book
  belongs_to :user

  validates :user_id, uniqueness: { scope: :book_id, message: "have already favourited this book" }
end
