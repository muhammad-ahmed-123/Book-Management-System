require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  test "anonymous can view index" do
    get books_url
    assert_response :success
  end

  test "anonymous can view show" do
    get book_url(books(:one))
    assert_response :success
  end

  test "anonymous can see a review's rating on the book show page" do
    get book_url(books(:one))
    assert_match "#{reviews(:one).rating}/5", response.body
  end

  test "anonymous redirected from new" do
    get new_book_url
    assert_redirected_to new_session_url
  end

  test "anonymous redirected from create" do
    assert_no_difference("Book.count") do
      post books_url, params: { book: { title: "X", author: "Y" } }
    end
    assert_redirected_to new_session_url
  end

  test "anonymous redirected from edit" do
    get edit_book_url(books(:one))
    assert_redirected_to new_session_url
  end

  test "anonymous redirected from update" do
    patch book_url(books(:one)), params: { book: { title: "Hacked" } }
    assert_redirected_to new_session_url
  end

  test "anonymous redirected from destroy" do
    assert_no_difference("Book.count") do
      delete book_url(books(:one))
    end
    assert_redirected_to new_session_url
  end

  test "owner can create a book owned by themselves" do
    sign_in_as users(:one)

    assert_difference("Book.count", 1) do
      post books_url, params: { book: { title: "New Book", author: "Me", description: "d" } }
    end

    assert_equal users(:one), Book.last.user
  end

  test "user_id cannot be spoofed via params on create" do
    sign_in_as users(:one)

    post books_url, params: { book: { title: "New Book", author: "Me", user_id: users(:two).id } }

    assert_equal users(:one), Book.last.user
  end

  test "owner can update their own book" do
    sign_in_as users(:one)

    patch book_url(books(:one)), params: { book: { title: "Updated Title" } }
    assert_redirected_to book_url(books(:one))
    assert_equal "Updated Title", books(:one).reload.title
  end

  test "owner can destroy their own book" do
    sign_in_as users(:one)

    assert_difference("Book.count", -1) do
      delete book_url(books(:one))
    end
  end

  test "non-owner cannot edit another user's book" do
    sign_in_as users(:two)

    get edit_book_url(books(:one))
    assert_redirected_to books_url
    follow_redirect!
    assert_equal "You are not authorized to edit that book.", flash[:alert]
  end

  test "non-owner cannot update another user's book" do
    sign_in_as users(:two)

    original_title = books(:one).title
    patch book_url(books(:one)), params: { book: { title: "Hacked" } }

    assert_redirected_to books_url
    assert_equal original_title, books(:one).reload.title
  end

  test "non-owner cannot destroy another user's book" do
    sign_in_as users(:two)

    assert_no_difference("Book.count") do
      delete book_url(books(:one))
    end
    assert_redirected_to books_url
  end
end
