class Book < ApplicationRecord
  belongs_to :user
  has_many :reviews, dependent: :destroy
  has_many :book_genres, dependent: :destroy
  has_many :genres, through: :book_genres

  validates :title, presence: true
  validates :author, presence: true
  validates :genres, presence: true
end
