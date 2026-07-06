class BooksController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_public_book, only: %i[ show ]
  before_action :set_own_book, only: %i[ edit update destroy ]

  def index
    @books = Book.includes(:genres).order(created_at: :desc)
  end

  def show
    @reviews = @book.reviews.includes(:user).order(created_at: :desc)
    @current_user_review = @book.reviews.find_by(user: Current.user) if authenticated?
  end

  def new
    @book = Book.new
  end

  def create
    @book = Current.user.books.build(book_params.merge(genre_ids: sanitized_genre_ids))

    if sanitized_genre_ids.empty?
      @book.errors.add(:genres, "can't be blank")
      render :new, status: :unprocessable_entity
    elsif @book.save
      redirect_to @book, notice: "Book was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if genre_ids_submitted? && sanitized_genre_ids.empty?
      @book.errors.add(:genres, "can't be blank")
      render :edit, status: :unprocessable_entity
    elsif @book.update(book_params_with_sanitized_genre_ids)
      redirect_to @book, notice: "Book was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: "Book was successfully deleted.", status: :see_other
  end

  private
    def set_public_book
      @book = Book.find_by(id: params[:id])
      redirect_to books_path, alert: "That book doesn't exist." unless @book
    end

    def set_own_book
      @book = Current.user.books.find_by(id: params[:id])
      redirect_to books_path, alert: "You are not authorized to edit that book." unless @book
    end

    def book_params
      params.require(:book).permit(:title, :author, :description, genre_ids: [])
    end

    def genre_ids_submitted?
      params[:book]&.key?(:genre_ids)
    end

    def sanitized_genre_ids
      Array(book_params[:genre_ids]).reject(&:blank?)
    end

    def book_params_with_sanitized_genre_ids
      return book_params unless genre_ids_submitted?
      book_params.merge(genre_ids: sanitized_genre_ids)
    end
end
