require "application_system_test_case"

class ReviewsTest < ApplicationSystemTestCase
  setup do
    @book_one = books(:one)   # owned by users(:one), already reviewed by users(:two)
    @book_two = books(:two)   # owned by users(:two), already reviewed by users(:three)
    @unreviewed_reviewer = users(:three)
    @other_unreviewed_reviewer = users(:one)
  end

  test "a signed in user can write a review for someone else's book" do
    sign_in_as_via_ui(@unreviewed_reviewer)
    visit book_url(@book_one)
    click_on "Write a Review"

    select "4", from: "Rating"
    fill_in "Body", with: "Really enjoyed this one."
    click_on "Create Review"

    assert_text "Review was successfully created."
    assert_text "★★★★☆"
    assert_text "Really enjoyed this one."
    assert_current_path book_path(@book_one)
  end

  test "submitting a review without a rating shows a validation error" do
    sign_in_as_via_ui(@unreviewed_reviewer)
    visit new_book_review_url(@book_one)

    fill_in "Body", with: "No rating given."
    click_on "Create Review"

    assert_text "Rating can't be blank"
  end

  test "submitting a review without a body shows a validation error" do
    sign_in_as_via_ui(@unreviewed_reviewer)
    visit new_book_review_url(@book_one)

    select "3", from: "Rating"
    disable_html5_validation
    click_on "Create Review"

    assert_text "Body can't be blank"
  end

  test "a book's owner does not see a Write a Review link and sees an explanatory note instead" do
    sign_in_as_via_ui(@book_one.user)
    visit book_url(@book_one)

    assert_no_link "Write a Review"
    assert_text "You can't review your own book."
  end

  test "a book's owner is redirected if they visit the new review form directly" do
    sign_in_as_via_ui(@book_one.user)
    visit new_book_review_url(@book_one)

    assert_current_path book_path(@book_one)
    assert_text "You can't review your own book."
  end

  test "a user who already reviewed a book sees an Edit your review link instead of Write a Review" do
    sign_in_as_via_ui(@other_unreviewed_reviewer)
    visit book_url(@book_two)
    click_on "Write a Review"
    select "5", from: "Rating"
    fill_in "Body", with: "First review."
    click_on "Create Review"

    visit book_url(@book_two)
    assert_link "Edit your review"
    assert_no_link "Write a Review"
  end

  test "a user cannot submit a second review for the same book by visiting the new form directly" do
    sign_in_as_via_ui(@other_unreviewed_reviewer)
    visit book_url(@book_two)
    click_on "Write a Review"
    select "5", from: "Rating"
    fill_in "Body", with: "First review."
    click_on "Create Review"

    visit new_book_review_url(@book_two)

    assert_current_path book_path(@book_two)
    assert_text "You have already reviewed this book. You can edit your existing review instead."
  end

  test "a user can edit their own review" do
    reviewer = reviews(:one).user
    sign_in_as_via_ui(reviewer)
    visit book_url(@book_one)
    # The show page renders an "Edit your review" link both inline on the
    # review itself and again in the reviewer-shortcut section below.
    click_on "Edit your review", match: :first

    select "2", from: "Rating"
    fill_in "Body", with: "Changed my mind on reflection."
    click_on "Update Review"

    assert_text "Review was successfully updated."
    assert_text "★★☆☆☆"
    assert_text "Changed my mind on reflection."
  end

  test "a user cannot edit another user's review by visiting the URL directly" do
    other_review = reviews(:one) # belongs to users(:two)
    sign_in_as_via_ui(@unreviewed_reviewer)

    visit edit_book_review_url(@book_one, other_review)

    assert_current_path book_path(@book_one)
    assert_text "You are not authorized to edit that review."
  end

  test "a user can delete their own review" do
    reviewer = reviews(:one).user
    sign_in_as_via_ui(reviewer)
    visit book_url(@book_one)

    click_on "Delete your review"

    assert_current_path book_path(@book_one)
    assert_text "Review was successfully deleted."
    assert_link "Write a Review"
  end
end
