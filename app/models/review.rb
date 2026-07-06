class Review < ApplicationRecord
  belongs_to :book
  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 1..5, message: "must be between 1 and 5" }
  validates :body, presence: true
  validates :user_id, uniqueness: { scope: :book_id, message: "have already reviewed this book" }

  validate :cannot_review_own_book

  private
    def cannot_review_own_book
      return if book.nil? || user.nil?
      errors.add(:base, "You can't review your own book") if book.user_id == user_id
    end
end
