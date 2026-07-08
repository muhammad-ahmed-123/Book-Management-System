class Comment < ApplicationRecord
  belongs_to :review
  belongs_to :user

  validates :body, presence: true, length: { minimum: 2, maximum: 500 }
end
