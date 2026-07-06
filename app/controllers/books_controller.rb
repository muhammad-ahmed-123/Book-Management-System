class BooksController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_public_book, only: %i[ show ]
  before_action :set_own_book, only: %i[ edit update destroy ]

  def index
    @books = Book.all.order(created_at: :desc)
  end

  def show
    @reviews = @book.reviews.includes(:user).order(created_at: :desc)
    @current_user_review = @book.reviews.find_by(user: Current.user) if Current.user
  end

  def new
    @book = Book.new
  end

  def create
    @book = Current.user.books.build(book_params)

    if @book.save
      redirect_to @book, notice: "Book was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @book.update(book_params)
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
      @book = Book.find(params[:id])
    end

    def set_own_book
      @book = Current.user.books.find_by(id: params[:id])
      redirect_to books_path, alert: "You are not authorized to edit that book." unless @book
    end

    def book_params
      params.require(:book).permit(:title, :author, :description)
    end
end
