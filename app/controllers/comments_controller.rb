class CommentsController < ApplicationController
  before_action :set_book
  before_action :set_review
  before_action :set_own_comment, only: %i[ destroy ]

  def create
    @comment = @review.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to @book, notice: "Comment was successfully added."
    else
      redirect_to @book, alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @comment.destroy
      redirect_to @book, notice: "Comment was successfully deleted.", status: :see_other
    else
      redirect_to @book, alert: "Comment couldn't be deleted. Please try again."
    end
  end

  private
    def set_book
      @book = Book.find_by(id: params[:book_id])
      redirect_to books_path, alert: "That book doesn't exist." unless @book
    end

    def set_review
      @review = @book.reviews.find_by(id: params[:review_id])
      redirect_to @book, alert: "That review doesn't exist." unless @review
    end

    def set_own_comment
      @comment = Current.user.comments.find_by(id: params[:id], review_id: params[:review_id])
      redirect_to @book, alert: "You are not authorized to delete that comment." unless @comment
    end

    def comment_params
      params.require(:comment).permit(:body)
    end
end
