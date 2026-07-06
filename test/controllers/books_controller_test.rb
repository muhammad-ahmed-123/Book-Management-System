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

  test "review author sees edit and delete controls for their own review on the book show page" do
    sign_in_as users(:two)

    get book_url(books(:one))
    assert_response :success
    assert_select "a[href=?]", edit_book_review_path(books(:one), reviews(:one)), text: "Edit your review"
    assert_select "form[action=?]", book_review_path(books(:one), reviews(:one))
  end

  test "non-author does not see edit and delete controls for another user's review" do
    sign_in_as users(:three)

    get book_url(books(:one))
    assert_response :success
    assert_select "a", text: "Edit your review", count: 0
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
      post books_url, params: { book: { title: "New Book", author: "Me", description: "d", genre_ids: [ genres(:fiction).id ] } }
    end

    assert_equal users(:one), Book.last.user
  end

  test "user_id cannot be spoofed via params on create" do
    sign_in_as users(:one)

    post books_url, params: { book: { title: "New Book", author: "Me", user_id: users(:two).id, genre_ids: [ genres(:fiction).id ] } }

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

  test "create without any genre selected is rejected and creates no book" do
    sign_in_as users(:one)

    assert_no_difference("Book.count") do
      post books_url, params: { book: { title: "New Book", author: "Me", genre_ids: [ "" ] } }
    end
    assert_response :unprocessable_entity
    assert_match "can&#39;t be blank", response.body
  end

  test "create with genre_ids assigns the selected genres" do
    sign_in_as users(:one)

    post books_url, params: { book: { title: "New Book", author: "Me", genre_ids: [ genres(:fiction).id, genres(:mystery).id ] } }

    assert_equal [ genres(:fiction), genres(:mystery) ].sort_by(&:id), Book.last.genres.sort_by(&:id)
  end

  test "update removing all genres is rejected and leaves the book's genres and other fields unchanged" do
    sign_in_as users(:one)
    original_title = books(:one).title
    original_genre_ids = books(:one).genre_ids.sort

    patch book_url(books(:one)), params: { book: { title: "Should not save", genre_ids: [ "" ] } }

    assert_response :unprocessable_entity
    books(:one).reload
    assert_equal original_title, books(:one).title
    assert_equal original_genre_ids, books(:one).genre_ids.sort
  end

  test "update can swap the selected genres" do
    sign_in_as users(:one)

    patch book_url(books(:one)), params: { book: { genre_ids: [ genres(:mystery).id ] } }

    assert_redirected_to book_url(books(:one))
    assert_equal [ genres(:mystery) ], books(:one).reload.genres
  end

  test "update omitting genre_ids entirely leaves existing genres untouched" do
    sign_in_as users(:one)
    original_genre_ids = books(:one).genre_ids.sort

    patch book_url(books(:one)), params: { book: { title: "Updated Title" } }

    assert_redirected_to book_url(books(:one))
    assert_equal original_genre_ids, books(:one).reload.genre_ids.sort
  end

  test "show displays the book's genres" do
    get book_url(books(:one))
    assert_match genres(:fiction).name, response.body
  end

  test "requesting a nonexistent book id redirects instead of raising" do
    get book_url(999999)
    assert_redirected_to books_url
    follow_redirect!
    assert_equal "That book doesn't exist.", flash[:alert]
  end

  test "requesting a non-numeric book id redirects instead of raising" do
    get "/books/abc"
    assert_redirected_to books_url
  end
end
