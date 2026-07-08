class Review < ApplicationRecord
  belongs_to :book
  belongs_to :user
  has_many :comments, dependent: :destroy

  validates :rating, presence: true, inclusion: { in: 1..5, message: "must be between 1 and 5" }
  validates :body, presence: true
  validates :user_id, uniqueness: { scope: :book_id, message: "have already reviewed this book" }
end
