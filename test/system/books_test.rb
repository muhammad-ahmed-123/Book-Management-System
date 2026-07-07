require "application_system_test_case"

class BooksTest < ApplicationSystemTestCase
  setup do
    @owner = users(:one)
    @other_user = users(:two)
    @book = books(:one)
  end

  test "an unauthenticated visitor can browse books but sees no owner controls" do
    visit books_url

    assert_text @book.title
    assert_no_link "New Book"
    assert_no_link "Edit", exact: true
    assert_no_button "Delete", exact: true
  end

  test "an unauthenticated visitor can view a book's show page but not review or edit it" do
    visit book_url(@book)

    assert_text @book.title
    assert_no_link "Edit", exact: true
    assert_no_button "Delete", exact: true
    assert_no_link "Write a Review"
  end

  test "a signed in user can create a book with a genre" do
    sign_in_as_via_ui(@owner)
    visit new_book_url

    fill_in "Title", with: "Practical Object-Oriented Design"
    fill_in "Author", with: "Sandi Metz"
    fill_in "Description", with: "A guide to OO design in Ruby."
    check "Fiction"
    click_on "Create Book"

    assert_text "Book was successfully created."
    assert_text "Practical Object-Oriented Design"
    assert_text "Fiction"
    assert_current_path book_path(Book.find_by(title: "Practical Object-Oriented Design"))
  end

  test "a signed in user can select multiple genres when creating a book" do
    sign_in_as_via_ui(@owner)
    visit new_book_url

    fill_in "Title", with: "Domain-Driven Design"
    fill_in "Author", with: "Eric Evans"
    check "Fiction"
    check "Mystery"
    click_on "Create Book"

    assert_text "Book was successfully created."
    assert_text "Fiction, Mystery"
  end

  test "creating a book without a title shows a validation error and does not save" do
    sign_in_as_via_ui(@owner)
    visit new_book_url

    fill_in "Author", with: "Some Author"
    check "Fiction"
    disable_html5_validation
    click_on "Create Book"

    assert_text "Title can't be blank"
    assert_current_path new_book_path
  end

  test "creating a book without selecting any genre shows a validation error" do
    sign_in_as_via_ui(@owner)
    visit new_book_url

    fill_in "Title", with: "No Genre Book"
    fill_in "Author", with: "Anon"
    click_on "Create Book"

    assert_text "Genres can't be blank"
    assert_nil Book.find_by(title: "No Genre Book")
  end

  test "the owner sees edit and delete controls on their own book" do
    sign_in_as_via_ui(@owner)
    visit book_url(@book)

    assert_link "Edit", exact: true
    assert_button "Delete"
  end

  test "a signed in user does not see edit or delete controls on another user's book" do
    sign_in_as_via_ui(@other_user)
    visit book_url(@book)

    assert_no_link "Edit", exact: true
    assert_no_button "Delete", exact: true
  end

  test "the owner can edit their own book, including changing genres" do
    sign_in_as_via_ui(@owner)
    visit book_url(@book)
    click_on "Edit"

    fill_in "Title", with: "The Pragmatic Programmer (2nd Edition)"
    uncheck "Fiction"
    check "Non-fiction"
    click_on "Update Book"

    assert_text "Book was successfully updated."
    assert_text "The Pragmatic Programmer (2nd Edition)"
    assert_text "Non-fiction"
  end

  test "removing all genres on update shows a validation error" do
    sign_in_as_via_ui(@owner)
    visit edit_book_url(@book)

    uncheck "Fiction"
    click_on "Update Book"

    assert_text "Genres can't be blank"
  end

  test "a user cannot reach the edit form for another user's book by visiting the URL directly" do
    sign_in_as_via_ui(@other_user)
    visit edit_book_url(@book)

    assert_current_path books_path
    assert_text "You are not authorized to edit that book."
  end

  test "the owner can delete their own book" do
    sign_in_as_via_ui(@owner)
    visit book_url(@book)

    click_on "Delete"

    assert_current_path books_path
    assert_text "Book was successfully deleted."
    assert_no_text @book.title
  end
end
