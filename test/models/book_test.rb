require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "invalid without title" do
    book = Book.new(author: "A", user: users(:one))
    assert_not book.valid?
  end

  test "invalid without author" do
    book = Book.new(title: "A Title", user: users(:one))
    assert_not book.valid?
  end

  test "valid without description" do
    book = Book.new(title: "A Title", author: "A", description: nil, user: users(:one))
    assert book.valid?
  end

  test "belongs to a user" do
    assert_equal users(:one), books(:one).user
  end
end
