require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test "anonymous redirected from new" do
    get new_book_review_url(books(:one))
    assert_redirected_to new_session_url
  end

  test "anonymous redirected from create" do
    assert_no_difference("Review.count") do
      post book_reviews_url(books(:one)), params: { review: { rating: 5, body: "x" } }
    end
    assert_redirected_to new_session_url
  end

  test "anonymous redirected from edit" do
    get edit_book_review_url(books(:one), reviews(:one))
    assert_redirected_to new_session_url
  end

  test "anonymous redirected from update" do
    patch book_review_url(books(:one), reviews(:one)), params: { review: { rating: 2 } }
    assert_redirected_to new_session_url
  end

  test "anonymous redirected from destroy" do
    assert_no_difference("Review.count") do
      delete book_review_url(books(:one), reviews(:one))
    end
    assert_redirected_to new_session_url
  end

  test "non-owner can create a review for someone else's book" do
    sign_in_as users(:three)

    assert_difference("Review.count", 1) do
      post book_reviews_url(books(:one)), params: { review: { rating: 4, body: "Great read" } }
    end

    assert_equal users(:three), Review.last.user
    assert_equal books(:one), Review.last.book
  end

  test "owner cannot view new form for own book" do
    sign_in_as users(:one)
    get new_book_review_url(books(:one))
    assert_redirected_to book_url(books(:one))
  end

  test "owner cannot create a review for their own book" do
    sign_in_as users(:one)

    assert_no_difference("Review.count") do
      post book_reviews_url(books(:one)), params: { review: { rating: 5, body: "self praise" } }
    end

    assert_redirected_to book_url(books(:one))
    follow_redirect!
    assert_equal "You can't review your own book.", flash[:alert]
  end

  test "self-review block cannot be bypassed by spoofing user_id in params" do
    sign_in_as users(:one)

    assert_no_difference("Review.count") do
      post book_reviews_url(books(:one)), params: { review: { rating: 5, body: "sneaky", user_id: users(:two).id } }
    end
  end

  test "cannot view new form when already reviewed" do
    sign_in_as users(:two)
    get new_book_review_url(books(:one))
    assert_redirected_to book_url(books(:one))
  end

  test "cannot create a second review for the same book" do
    sign_in_as users(:two)

    assert_no_difference("Review.count") do
      post book_reviews_url(books(:one)), params: { review: { rating: 1, body: "again" } }
    end

    follow_redirect!
    assert_equal "You have already reviewed this book. You can edit your existing review instead.", flash[:alert]
  end

  test "book_id and user_id cannot be spoofed via params on create" do
    sign_in_as users(:three)

    post book_reviews_url(books(:one)), params: { review: { rating: 4, body: "ok", book_id: books(:two).id, user_id: users(:one).id } }

    assert_equal books(:one), Review.last.book
    assert_equal users(:three), Review.last.user
  end

  test "owner can update their own review" do
    sign_in_as users(:two)

    patch book_review_url(books(:one), reviews(:one)), params: { review: { rating: 3, body: "Updated opinion" } }

    assert_redirected_to book_url(books(:one))
    assert_equal 3, reviews(:one).reload.rating
  end

  test "owner can destroy their own review" do
    sign_in_as users(:two)

    assert_difference("Review.count", -1) do
      delete book_review_url(books(:one), reviews(:one))
    end
  end

  test "non-author cannot edit another user's review" do
    sign_in_as users(:one)

    get edit_book_review_url(books(:one), reviews(:one))
    assert_redirected_to book_url(books(:one))
    follow_redirect!
    assert_equal "You are not authorized to edit that review.", flash[:alert]
  end

  test "non-author cannot update another user's review" do
    sign_in_as users(:one)
    original_rating = reviews(:one).rating

    patch book_review_url(books(:one), reviews(:one)), params: { review: { rating: 1, body: "hijacked" } }

    assert_redirected_to book_url(books(:one))
    assert_equal original_rating, reviews(:one).reload.rating
  end

  test "non-author cannot destroy another user's review" do
    sign_in_as users(:one)

    assert_no_difference("Review.count") do
      delete book_review_url(books(:one), reviews(:one))
    end
    assert_redirected_to book_url(books(:one))
  end

  test "invalid rating on create re-renders new with 422" do
    sign_in_as users(:three)

    assert_no_difference("Review.count") do
      post book_reviews_url(books(:one)), params: { review: { rating: 0, body: "x" } }
    end
    assert_response :unprocessable_entity
  end

  test "blank body on create re-renders new with 422" do
    sign_in_as users(:three)

    assert_no_difference("Review.count") do
      post book_reviews_url(books(:one)), params: { review: { rating: 4, body: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "invalid rating on update re-renders edit with 422" do
    sign_in_as users(:two)

    patch book_review_url(books(:one), reviews(:one)), params: { review: { rating: 7 } }

    assert_response :unprocessable_entity
    assert_not_equal 7, reviews(:one).reload.rating
  end

  test "anonymous can see reviews on the book's show page" do
    get book_url(books(:one))
    assert_response :success
    assert_match reviews(:one).body, response.body
  end

  test "requesting a nonexistent book_id redirects instead of raising" do
    sign_in_as users(:two)

    get new_book_review_url(999999)

    assert_redirected_to books_url
    follow_redirect!
    assert_equal "That book doesn't exist.", flash[:alert]
  end

  test "requesting a non-numeric book_id redirects instead of raising" do
    sign_in_as users(:two)

    get "/books/abc/reviews/new"

    assert_redirected_to books_url
  end
end
