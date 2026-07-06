require "test_helper"

class GenreTest < ActiveSupport::TestCase
  test "invalid without a name" do
    genre = Genre.new(name: nil)
    assert_not genre.valid?
  end

  test "invalid with a duplicate name" do
    genre = Genre.new(name: genres(:fiction).name)
    assert_not genre.valid?
  end

  test "invalid with a duplicate name in different case" do
    genre = Genre.new(name: genres(:fiction).name.upcase)
    assert_not genre.valid?
  end

  test "has many books through book_genres" do
    assert_includes genres(:fiction).books, books(:one)
  end
end
