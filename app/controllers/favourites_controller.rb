class FavouritesController < ApplicationController
  rescue_from ActiveRecord::RecordNotUnique, with: :handle_duplicate_favourite_race

  before_action :set_book, only: %i[ create destroy ]
  before_action :set_own_favourite, only: %i[ destroy ]

  def index
    @books = Current.user.favourite_books.includes(:genres).order("favourites.created_at DESC")
  end

  def create
    @favourite = Current.user.favourites.build(book: @book)

    if @favourite.save
      redirect_back_or_to @book, notice: "Book added to your favourites.", allow_other_host: false
    else
      redirect_back_or_to @book, alert: @favourite.errors.full_messages.to_sentence, allow_other_host: false
    end
  end

  def destroy
    if @favourite.destroy
      redirect_back_or_to @book, notice: "Book removed from your favourites.", allow_other_host: false
    else
      redirect_back_or_to @book, alert: "Book couldn't be removed from your favourites. Please try again.", allow_other_host: false
    end
  end

  private
    def set_book
      @book = Book.find_by(id: params[:book_id])
      redirect_to books_path, alert: "That book doesn't exist." unless @book
    end

    def set_own_favourite
      @favourite = Current.user.favourites.find_by(book_id: @book.id)
      redirect_back_or_to @book, alert: "You haven't favourited this book.", allow_other_host: false unless @favourite
    end

    def handle_duplicate_favourite_race
      redirect_back_or_to @book, alert: "You have already added this book to your favourites.", allow_other_host: false
    end
end
