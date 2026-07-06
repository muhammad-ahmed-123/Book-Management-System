require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "valid with rating, body, book, and a user who isn't the book's owner" do
    review = Review.new(rating: 4, body: "Solid read.", book: books(:one), user: users(:three))
    assert review.valid?
  end

  test "invalid without rating" do
    review = Review.new(rating: nil, body: "x", book: books(:one), user: users(:three))
    assert_not review.valid?
  end

  test "invalid with rating 0" do
    review = Review.new(rating: 0, body: "x", book: books(:one), user: users(:three))
    assert_not review.valid?
  end

  test "invalid with rating 6" do
    review = Review.new(rating: 6, body: "x", book: books(:one), user: users(:three))
    assert_not review.valid?
  end

  test "invalid with negative rating" do
    review = Review.new(rating: -1, body: "x", book: books(:one), user: users(:three))
    assert_not review.valid?
  end

  test "invalid with non-integer rating" do
    review = Review.new(rating: "abc", body: "x", book: books(:one), user: users(:three))
    assert_not review.valid?
  end

  test "invalid without body" do
    review = Review.new(rating: 4, body: nil, book: books(:one), user: users(:three))
    assert_not review.valid?
  end

  test "invalid with blank body" do
    review = Review.new(rating: 4, body: "", book: books(:one), user: users(:three))
    assert_not review.valid?
  end

  test "invalid if user already reviewed this book" do
    review = Review.new(rating: 2, body: "second opinion", book: books(:one), user: users(:two))
    assert_not review.valid?
    assert_includes review.errors[:user_id], "have already reviewed this book"
  end

  test "invalid if reviewing own book" do
    review = Review.new(rating: 5, body: "self praise", book: books(:one), user: users(:one))
    assert_not review.valid?
    assert_includes review.errors[:base], "You can't review your own book"
  end

  test "belongs to a book and a user" do
    assert_equal books(:one), reviews(:one).book
    assert_equal users(:two), reviews(:one).user
  end

  test "database enforces one review per user per book even bypassing validations" do
    duplicate = Review.new(rating: 1, body: "dupe", book: books(:one), user: users(:two))
    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save(validate: false)
    end
  end

  test "destroying a book destroys its reviews" do
    assert_difference("Review.count", -1) do
      books(:one).destroy
    end
  end

  test "destroying a user destroys their reviews" do
    assert_difference("Review.count", -1) do
      users(:three).destroy
    end
  end
end
