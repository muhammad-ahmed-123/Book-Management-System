require "rails_helper"

RSpec.describe Genre, type: :model do
  describe "validations" do
    subject { Genre.create!(name: "Fiction") }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end
end