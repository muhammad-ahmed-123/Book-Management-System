class ReviewsController < ApplicationController
  rescue_from ActiveRecord::RecordNotUnique, with: :handle_duplicate_review_race

  before_action :set_book
  before_action :block_self_review, only: %i[ new create ]
  before_action :block_duplicate_review, only: %i[ new create ]
  before_action :set_own_review, only: %i[ edit update destroy ]

  def new
    @review = @book.reviews.build
  end

  def create
    @review = @book.reviews.build(review_params)
    @review.user = Current.user

    if @review.save
      redirect_to @book, notice: "Review was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to @book, notice: "Review was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to @book, notice: "Review was successfully deleted.", status: :see_other
  end

  private
    def set_book
      @book = Book.find(params[:book_id])
    end

    def block_self_review
      if @book.user_id == Current.user.id
        redirect_to @book, alert: "You can't review your own book."
      end
    end

    def block_duplicate_review
      if @book.reviews.exists?(user_id: Current.user.id)
        redirect_to @book, alert: "You have already reviewed this book. You can edit your existing review instead."
      end
    end

    def set_own_review
      @review = Current.user.reviews.find_by(id: params[:id], book_id: params[:book_id])
      redirect_to @book, alert: "You are not authorized to edit that review." unless @review
    end

    def review_params
      params.require(:review).permit(:rating, :body)
    end

    def handle_duplicate_review_race
      redirect_to @book, alert: "You have already reviewed this book. You can edit your existing review instead."
    end
end
