require 'rails_helper'
require_relative '../support/subjects_ui_helper.rb'

RSpec.feature "AuthzTags", type: :feature, js:true do
  include_context "db_cleanup_each"
  include SubjectsUiHelper

  let(:authenticated) { create_user }
  let(:originator)    { create_user }
  let(:organizer)     { originator }
  let(:admin)         { apply_admin create_user }
  let(:tag_props)     { FactoryGirl.attributes_for(:tag) }
  let(:tags)          { FactoryGirl.create_list(:tag, 3,
                                                :with_roles,
                                                :creator_id=>originator[:id])}
  let(:tag)         { tags[0] }

  shared_examples "can list tags" do
    it "lists tags" do
      visit_tags tags
      within("sd-tag-selector .tag-list") do
        tags.each do |tg|
          expect(page).to have_css("li a",:text=>tg.name)
          expect(page).to have_css(".tag_id",:text=>tg.id,:visible=>false)
          expect(page).to have_no_css(".tag_id")
        end
      end
    end
  end

  shared_examples "displays correct buttons for role" do |displayed,not_displayed|
    it "displays correct buttons" do
      within("sd-tag-editor .tag-form") do
        displayed.each do |button|
          disabled_value = ["Update Tag"].include? button
          expect(page).to have_button(button,:disabled=>disabled_value)
        end
        not_displayed.each do |button|
          expect(page).to have_no_button(button)
        end
      end
    end
  end
  shared_examples "can create tag" do
    it "creates tag" do
      within("sd-tag-editor .tag-form") do
        expect(page).to have_button("Create Tag",:wait=>5)
        expect(page).to have_field("tag-caption",:readonly=>false)
        fill_in("tag-name", :with=>tag_props[:name])
        expect(page).to have_field("tag-name",:with=>tag_props[:name])
        click_button("Create Tag",:disabled=>false,:wait=>5)
        expect(page).to have_button("Clear Tag",:wait=>5)
        expect(page).to have_button("Delete Tag",:wait=>5)
        expect(page).to have_button("Update Tag", :disabled=>true)
        expect(page).to have_no_button("Create Tag")
        click_button("Clear Tag")
        expect(page).to have_no_button("Clear Tag",:wait=>5)
        expect(page).to have_field("tag-name", :with=>"")
        expect(page).to have_button("Create Tag")
      end

      #list should now have new value
      within("sd-tag-selector .tag-list") do
        expect(page).to have_css("li a", :text=>/^#{tag_props[:name]}/, :wait=>5)
      end
    end
  end
  shared_examples "displays tag" do
    it "field filled in with clicked tag name" do
      within("sd-tag-editor .tag-form") do
        expect(page).to have_field("tag-name", :with=>tag.name)
        expect(page).to have_css(".tag_id",:text=>tag.id,:visible=>false)
        expect(page).to have_no_css(".tag_id")
      end
    end
  end
  shared_examples "can clear tag" do
    it "tag name cleared from input field" do
      within("sd-tag-editor .tag-form") do
        #we start out with name filled in and button(s) displayed
        expect(page).to have_css(".id", :text=>tag.id, :visible=>false)
        expect(page).to have_field("tag-name", :with=>tag.name)
        expect(page).to have_no_field("tag-name", :with=>"")

        #clear the selected image
        click_button("Clear Tag")

        #input field should be cleared
        expect(page).to have_no_field("tag-name", :with=>tag.name)
        expect(page).to have_field("tag-name", :with=>"")
        expect(page).to have_no_button("Clear Tag")
        expect(page).to have_no_css(".id", :text=>tag.id, :visible=>false)
      end
    end
  end
  shared_examples "cannot update tag" do
    it "name is not updatable" do
      within("sd-tag-editor .tag-form") do
        #wait for controls to load
        expect(page).to have_button("Clear Tag")
        expect(page).to have_field("tag-name", :with=>tag.name, :readonly=>true)
      end
    end
  end

  shared_examples "can update tag" do
    it "name is updated" do
      new_name="new name"

      #find(first_link_css).click
      within("sd-tag-editor .tag-form") do
        #we start out with caption filled in and button(s) displayed
        expect(page).to have_field("tag-name", :with=>tag.name)

        #update the input field
        fill_in("tag-name", :with=>new_name)
        click_button("Update Tag")

        #wait for update to initiate before navigating to new page
        expect(page).to have_button("Update Tag", :disabled=>true)
        expect(page).to have_field("tag-name", :with=>new_name)
        5.times do #Clear button does not always go away
          click_button("Clear Tag")
          break if page.has_no_button?("Clear Tag")
        end
        expect(page).to have_no_button("Clear Tag")
        expect(page).to have_field("tag-name", :with=>"")
        expect(page).to have_button("Create Tag")
      end

      #list should now have new value
      within("sd-tag-selector .tag-list") do
        expect(page).to have_css("li a", :text=>/^#{new_name}/, :wait=>5)
      end
      #verify exists on server after page refresh following logout
      logout
      within("sd-tag-selector .tag-list") do
        expect(page).to have_css("li a", :text=>/^#{new_name}/, :wait=>5)
      end
    end
  end
  shared_examples "can delete tag" do
    it "tag deleted" do
      within("sd-tag-editor .tag-form") do
        #delete the image
        click_button("Delete Tag")

        #wait for delete to initiate before navigating to new page
        expect(page).to have_no_button("Delete Tag")
        expect(page).to have_button("Create Tag")
      end

      #item should now be gone
      within("sd-tag-selector .tag-list") do
        expect(page).to have_css("span.tag_id",:count=>2,:visible=>false,:wait=>5)
        expect(page).to have_no_css("span.tag_id",:text=>tag.id,:visible=>false)
      end
    end
  end

  context "no tag selected" do
    after(:each) { logout }

    context "unauthenticated user" do
      before(:each) { logout; visit_tags tags }
      it_behaves_like "can list tags"
      it_behaves_like "displays correct buttons for role",
            [],
            ["Create Tag", "Clear Tag", "Update Tag", "Delete Tag"]
    end
    context "authenticated user" do
      before(:each) { login authenticated; visit_tags tags }
      it_behaves_like "can list tags"
      it_behaves_like "displays correct buttons for role",
            ["Create Tag"],
            ["Clear Tag", "Update Tag", "Delete Tag"]
      it_behaves_like "can create tag"
    end
    context "organizer user" do
      before(:each) { login organizer; visit_tags tags }
      it_behaves_like "displays correct buttons for role",
            ["Create Tag"],
            ["Clear Tag", "Update Tag", "Delete Tag"]
      it_behaves_like "can create tag"
    end
    context "admin user" do
      before(:each) { login admin; visit_tags tags }
      it_behaves_like "displays correct buttons for role",
            ["Create Tag"],
            ["Clear Tag", "Update Tag", "Delete Tag"]
      it_behaves_like "can create tag"
    end
  end

  context "tags posted" do
    before(:each) do
      visit_tags tags
    end
    after(:each) { logout }

    context "user selects tag" do
      before(:each) do
        find("div.tag-list .id",:text=>tag.id, :visible=>false).find(:xpath,"..").click
      end
      it_behaves_like "displays tag"

      context "unauthenticated user" do
        before(:each) { logout }
        it_behaves_like "displays correct buttons for role",
              ["Clear Tag"],
              ["Create Tag", "Update Tag", "Delete Tag"]
        it_behaves_like "can clear tag"
        it_behaves_like "cannot update tag"
      end
      context "authenticated user" do
        before(:each) { login authenticated; find(".tag-controls") }
        it_behaves_like "displays correct buttons for role",
              ["Clear Tag"],
              ["Create Tag", "Update Tag", "Delete Tag"]
        it_behaves_like "can clear tag"
        it_behaves_like "cannot update tag"
      end
      context "organizer user" do
        before(:each) { login organizer; find(".tag-controls > span") }
        it_behaves_like "displays correct buttons for role",
              ["Clear Tag", "Update Tag", "Delete Tag"],
              ["Create Tag"]
        it_behaves_like "can clear tag"
        it_behaves_like "can update tag"
        it_behaves_like "can delete tag"
      end
      context "admin user" do
        before(:each) { login admin; find(".tag-controls > span") }
        it_behaves_like "displays correct buttons for role",
              ["Clear Tag", "Delete Tag"],
              ["Create Tag", "Update Tag"]
        it_behaves_like "can clear tag"
        it_behaves_like "cannot update tag"
        it_behaves_like "can delete tag"
      end
    end
  end
end
