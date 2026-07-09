require "rails_helper"

RSpec.describe "Comments", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:book) { create(:book, user: owner) }
  let(:review) { create(:review, book: book) }
  let(:comment) { create(:comment, review: review, user: other_user) }

  describe "POST /books/:book_id/reviews/:review_id/comments" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        post book_review_comments_path(book, review), params: { comment: { body: "Great!" } }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in(other_user) }

      it "creates a comment" do
        expect {
          post book_review_comments_path(book, review), params: { comment: { body: "Great point!" } }
        }.to change(Comment, :count).by(1)

        expect(Comment.last.user).to eq(other_user)
        expect(flash[:notice]).to be_present
      end

      it "ignores spoofed review_id or user_id in params" do
        other_review = create(:review)
        params = { comment: { body: "ok", review_id: other_review.id, user_id: owner.id } }

        post book_review_comments_path(book, review), params: params

        expect(Comment.last.review).to eq(review)
        expect(Comment.last.user).to eq(other_user)
      end

      it "fails gracefully with validation errors" do
        post book_review_comments_path(book, review), params: { comment: { body: "x" } }
        
        expect(response).to redirect_to(book_path(book))
        expect(flash[:alert]).to include("too short")
      end
    end

    context "when parent resources are invalid" do
      before { sign_in(other_user) }

      it "redirects when the book is not found" do
        post "/books/invalid/reviews/#{review.id}/comments", params: { comment: { body: "Hi" } }
        expect(response).to redirect_to(books_path)
      end

      it "redirects when the review is not found or belongs to another book" do
        post "/books/#{book.id}/reviews/invalid/comments", params: { comment: { body: "Hi" } }
        expect(response).to redirect_to(book_path(book))
      end
    end
  end

  describe "DELETE /books/:book_id/reviews/:review_id/comments/:id" do
    let!(:target_comment) { comment }

    it "destroys the comment if authored by the current user" do
      sign_in(other_user)

      expect {
        delete book_review_comment_path(book, review, target_comment)
      }.to change(Comment, :count).by(-1)
    end

    it "prevents destruction if unauthorized" do
      sign_in(owner)

      expect {
        delete book_review_comment_path(book, review, target_comment)
      }.not_to change(Comment, :count)
      
      expect(flash[:alert]).to be_present
    end

    it "fails gracefully on unexpected exceptions" do
      sign_in(other_user)
      allow_any_instance_of(Comment).to receive(:destroy).and_return(false)

      delete book_review_comment_path(book, review, target_comment)

      expect(flash[:alert]).to include("couldn't be deleted")
    end
  end
end