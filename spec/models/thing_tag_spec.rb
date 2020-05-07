require 'rails_helper'

RSpec.describe ThingTag, type: :model do
  include_context "db_cleanup_each"

  context "valid thing" do
    let(:thing) { FactoryGirl.build(:thing) }

    it "build tag for thing and save" do
      tt = FactoryGirl.build(:thing_tag, :thing=>thing)
      tt.save!
      expect(thing).to be_persisted
      expect(tt).to be_persisted
      expect(tt.tag).to_not be_nil
      expect(tt.tag).to be_persisted
    end

    it "relate multiple tags" do
      thing.thing_tags << FactoryGirl.build_list(:thing_tag, 3, :thing=>thing)
      thing.save!
      expect(Thing.find(thing.id).thing_tags.size).to eq(3)

      thing.thing_tags.each do |tt|
        expect(tt.tag.things.first).to eql(thing) #same instance
      end
    end

    it "build tags using factory" do
      thing=FactoryGirl.create(:thing, :with_tag, :tag_count=>2)
      expect(Thing.find(thing.id).thing_tags.size).to eq(2)
      thing.thing_tags.each do |tt|
        expect(tt.tag.things.first).to eql(thing) #same instance
      end
    end
  end

  context "related thing and tag" do
    let(:thing) { FactoryGirl.create(:thing, :with_tag) }
    let(:thing_tag) { thing.thing_tags.first }
    before(:each) do
      #sanity check that objects and relationships are in place
      expect(ThingTag.where(:id=>thing_tag.id).exists?).to be true
      expect(Tag.where(:id=>thing_tag.tag_id).exists?).to be true
      expect(Thing.where(:id=>thing_tag.thing_id).exists?).to be true
    end
    after(:each) do
      #we always expect the thing_tag to be deleted during each test
      expect(ThingTag.where(:id=>thing_tag.id).exists?).to be false
    end

    it "deletes link but not tag when thing removed" do
      thing.destroy
      expect(Tag.where(:id=>thing_tag.tag_id).exists?).to be true
      expect(Thing.where(:id=>thing_tag.thing_id).exists?).to be false
    end

    it "deletes link but not thing when tag removed" do
      thing_tag.tag.destroy
      expect(Tag.where(:id=>thing_tag.tag_id).exists?).to be false
      expect(Thing.where(:id=>thing_tag.thing_id).exists?).to be true
    end
  end
end
