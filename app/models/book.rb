class Book < ApplicationRecord
  belongs_to :user
  has_many :reviews, dependent: :destroy
  has_many :favourites, dependent: :destroy
  has_many :book_genres, dependent: :destroy
  has_many :genres, through: :book_genres

  validates :title, presence: true, length: { minimum: 3, maximum: 30 }
  validates :author, presence: true, length: { minimum: 3, maximum: 30 }
  validates :genres, presence: true
  validates :description, length: { maximum: 500 }
end
