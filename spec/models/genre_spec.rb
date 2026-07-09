require "rails_helper"

RSpec.describe Genre, type: :model do
  describe "validations" do
    it "requires a name" do
      genre = Genre.new(name: nil)
      expect(genre).not_to be_valid
      expect(genre.errors[:name]).to include("can't be blank")
    end

    it "requires a unique name regardless of case" do
      Genre.create!(name: "Fiction")
      duplicate = Genre.new(name: "fiction")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end
end
