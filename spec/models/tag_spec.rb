require 'rails_helper'

RSpec.describe Tag, type: :model do
  include_context "db_cleanup"

  context "build valid tag" do
    it "default tag created with random name" do
      user=FactoryGirl.create(:user)
      tag=FactoryGirl.build(:tag, :creator_id=>user.id)
      expect(tag.creator_id).to eq(user.id)
      expect(tag.name).to_not be_nil
      expect(tag.save).to be true
    end
  end
end
