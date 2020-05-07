require 'rails_helper'

RSpec.describe "Tags", type: :request do
  include_context "db_cleanup_each"
  let!(:account) { signup FactoryGirl.attributes_for(:user) }

  context "quick API check" do
    let!(:user) { login account }

    it_should_behave_like "resource index", :tag
    it_should_behave_like "show resource", :tag
    it_should_behave_like "create resource", :tag
    it_should_behave_like "modifiable resource", :tag
  end

  shared_examples "cannot create" do
    it "create fails" do
      jpost tags_path, tag_props
      expect(response.status).to be >= 400
      expect(response.status).to be < 500
      expect(parsed_body).to include("errors")
    end
  end
  shared_examples "can create" do
    it "can create" do
      jpost tags_path, tag_props
      expect(response).to have_http_status(:created)
      payload=parsed_body
      expect(payload).to include("id")
      expect(payload).to include("name" => tag_props[:name])
    end
  end
  shared_examples "all fields present" do
    it "list has all fields" do
      jget tags_path
      expect(response).to have_http_status(:ok)
      payload=parsed_body
      expect(payload.size).to_not eq(0)
      payload.each do |r|
        expect(r).to include("id")
        expect(r).to include("name")
      end
    end
    it "get has all fields" do
      jget tag_path(tag.id)
      expect(response).to have_http_status(:ok)
      payload=parsed_body
      expect(payload).to include("id"=>tag.id)
      expect(payload).to include("name"=>tag.name)
    end
  end
  describe "access" do
    let(:tags_props) { (1..3).map {FactoryGirl.attributes_for(:tag)} }
    let(:tag_props) { tags_props[0] }
    let!(:tags) { Tag.create(tags_props) }
    let(:tag) { tags[0] }

    context "unauthenticated caller" do
      before(:each) { logout nil }
      it_should_behave_like "cannot create"
      it_should_behave_like "all fields present"
    end
    context "unauthenticated caller" do
      before(:each) { login account }
      it_should_behave_like "can create"
      it_should_behave_like "all fields present"
    end
  end
end
