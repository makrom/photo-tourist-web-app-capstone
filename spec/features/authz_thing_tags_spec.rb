require 'rails_helper'
require_relative '../support/subjects_ui_helper.rb'

RSpec.feature "AuthzThingTags", type: :feature, :js=>true do
  include_context "db_cleanup_each"
  include SubjectsUiHelper

  let(:admin)         { apply_admin(create_user) }
  let(:originator)    { apply_originator(create_user, Thing) }
  let(:organizer)     { originator }
  let(:member)        { create_user }
  let(:alt_member)    { create_user }
  let(:authenticated) { create_user }
  let(:thing_props)   { FactoryGirl.attributes_for(:thing) }
  let(:things)        { FactoryGirl.create_list(:thing, 3) }
  let(:things)        { FactoryGirl.create_list(:thing, 3,
                                                :with_roles,
                                                :originator_id=>originator[:id],
                                                :member_id=>member[:id]) }
  let(:alt_things)    { FactoryGirl.create_list(:thing, 1,
                                                :with_roles,
                                                :originator_id=>originator[:id],
                                                :member_id=>alt_member[:id]) }
  let(:tags) { FactoryGirl.create_list(:tag, 3,
                                         :with_roles,
                                         :creator_id=>authenticated[:id]) }
  let(:linked_thing)  { things[0] }
  let(:linked_tag)  { tags[0] }
  let(:thing_tag) { FactoryGirl.create(:thing_tag,
                                         :thing=>linked_thing,
                                         :tag=>linked_tag,
                                         :creator_id=>member[:id]) }

  before(:each) do
    #touch these before we start
    thing_tag
    alt_things
    visit ui_path
  end

  shared_examples "can get links" do
    context "from tags" do
      before(:each) { visit_tag linked_tag }
      it "can view linked things for tag" do
        within("sd-tag-editor") do
          expect(page).to have_css("div.tag-things")
          within("div.tag-things") do
            expect(page).to have_css("label", :text=>"Related Things")
            expect(page).to have_css("li a", :text=>linked_thing.name)
            expect(page).to have_css("li span.thing_id",
                                     :text=>linked_thing.id,
                                     :visible=>false)
            expect(page).to have_no_css("li span.thing_id") #should be hidden
          end
        end
        #make sure all updates received from server before quitting
        tag_editor_loaded! linked_tag
      end
      it "can navigate from tag to thing" do
        pp linked_thing
        byebug
        expect(page).to have_css("sd-tag-editor")
        link_selector_args=["sd-tag-editor ul.tag-things span.thing_id",
                            {:text=>linked_thing.id, :visible=>false, :wait=>5}]

        #extend timeouts for an extensive amount of concurrent, async activity
        using_wait_time 5 do
          #wait for the link to show up and then click
          find(*link_selector_args).find(:xpath,"..").click
          #wait for page to react to link and switch away
          expect(page).to have_no_css(*link_selector_args)
          expect(page).to have_no_css("sd-tag-editor")

          #wait for page navigated to arrive, displaying expected
          thing_editor_loaded! linked_thing
        end
      end
    end
    context "from things" do
      before(:each) { visit_thing linked_thing }
      it "can view linked tags for thing" do
        expect(page).to have_css("sd-thing-editor")
        within("sd-thing-editor .thing-form ul.thing-tags",:wait=>5) do
          expect(page).to have_css("li span.tag_id",
                                   :text=>linked_tag.id,
                                   :visible=>false,
                                   :wait=>5)
          expect(page).to have_css("li label.tag-name",
                                   :text=>linked_tag.name)
          #no link should show that it has been modified
          expect(page).to have_no_css("li div.glyphicon-asterisk")
        end
      end
      it "can navigate from thing to tag" do
        expect(page).to have_css("sd-thing-editor")

        #wait for the link to show up and then click
        within("sd-thing-editor .thing-form ul.thing-tags") do
          node=find("li span.tag_id",:text=>linked_tag.id,
                                  :visible=>false,
                                  :wait=>5).find(:xpath,"../label").click
        end

        #wait for page to react to link and switch away
        expect(page).to have_no_css("sd-thing-editor")

        #wait for page navigated to arrive, displaying expected
        tag_editor_loaded! linked_tag
      end
    end
  end

  #we mean links to specific things
  shared_examples "can create links" do
    before(:each) { visit_tag linked_tag }

    it "can get linkable things for tag" do
      linkables=get_linkables(linked_tag)
      # verify page contains option to select unlinked things
      within("sd-tag-editor .tag-form .linkable-things") do
        expect(page).to have_css(".link-things select option", :count=>linkables.size, :wait=>5)
        (1..2).each do |i|
          expect(page).to have_css(".link-things select option", :text=>things[i].name)
          expect(page).to have_css(".link-things select option[value='#{things[i].id}']")
        end
        # verify page does not contain option to already linked things
        expect(page).to have_no_css(".link-things select option[value='#{linked_thing.id}']")
      end
      #make sure page finishes loading before ending test
      tag_editor_loaded! linked_tag, linkables.size
    end

    it "can create link tag to things" do
      within("sd-tag-editor .tag-form") do
        #verify new thing not in linked things
        expect(page).to have_css("ul.tag-things li a", :text=>linked_thing.name,:wait=>5)
        expect(page).to have_no_css("ul.tag-things li a", :text=>things[1].name)

        #click on option
        find(".link-things select option", :text=>things[1].name).select_option
        button=page.has_button?("Update Tag") ? "Update Tag" : "Link to Things"
        click_button(button)
        expect(page).to have_button(button,:disabled=>true,:wait=>5)

        #was added to linked things
        expect(page).to have_css("ul.tag-things li a", :text=>linked_thing.name)
        expect(page).to have_css("ul.tag-things li a", :text=>things[1].name)
        expect(page).to have_css("ul.tag-things li span.thing_id",
                                 :text=>things[1].id, :visible=>false)
      end
    end

    it "removes thing from linkables when linked" do
      linkables=get_linkables(linked_tag)
      within("sd-tag-editor .tag-form") do
        expect(page).to have_css(".link-things select option", :count=>linkables.size, :wait=>5)
        #select one of the linkables and link to tag
        using_wait_time 5 do # given extra time for related calls to complete
          find(".link-things select option", :text=>things[1].name).select_option
          #save_and_open_page
        end
        button=page.has_button?("Update Tag") ? "Update Tag" : "Link to Things"
        expect(page).to have_button(button,:disabled=>false)
        click_button(button)
        expect(page).to have_button(button,:disabled=>true,:wait=>5)

        #once linked, the thing should no longer show up in the linkables
        expect(page).to have_no_css(".link-things select option", :text=>things[1].name)

        #wait for async server updated to complete
        expect(page).to have_css("ul.tag-things li span.thing_id",
                                 :text=>things[1].id, :visible=>false, :wait=>5)
      end
      #try to wait for all requests to server to complete before exiting
      tag_editor_loaded! linked_tag, linkables.size-1
    end

    it "removes link button when no linkables" do
      linkables=get_linkables(linked_tag)
      within("sd-tag-editor .tag-form") do
        #wait for the list to be displayed
        expect(page).to have_css(".link-things select option", :count=>linkables.size, :wait=>5)

        #select all of the expected linkables and link to tag
        all(".link-things select option").each do |option|
            option.select_option
        end
        button=page.has_button?("Update Tag") ? "Update Tag" : "Link to Things"
        click_button(button)
        #Note ID goes away briefly during the reload(), causing these buttons to blink
        expect(page).to have_button(button,:disabled=>true,:wait=>5)

        #wait for page to update
        expect(page).to have_css("ul.tag-things li span.thing_id",
                                 :text=>things[1].id, :visible=>false, :wait=>5)
      end
    end
  end

  #we mean links to specific things
  shared_examples "cannot create link" do
    before(:each) { visit_tag linked_tag }
    it "shows no linkable things for tag" do
      within("sd-tag-editor .tag-form") do
        things.each do |thing|
          expect(page).to have_no_css("select option", :text=>thing.name)
        end
      end
    end
  end

  shared_examples "can edit link" do
    before(:each) { visit_thing linked_thing }

    it "update disabled until dirty edit" do
      within("sd-thing-editor .thing-form") do
        expect(page).to have_button("Update Thing",:disabled=>true)
        expect(page).to have_no_button("Update Tag Links")

        #editing only a link causes only the link update to be enabled
        expect(page).to have_no_button("Update Thing")
        expect(page).to have_button("Update Tag Links", :disabled=>false)

        #editing name causes entire object update to be enabled
        find_field("thing-name", :with=>linked_thing.name)
        fill_in("thing-name", :with=>"new name")
        expect(page).to have_button("Update Thing", :disabled=>false)
        expect(page).to have_no_button("Update Tag Links")
      end
    end

  end

  shared_examples "can remove link" do |role|
    before(:each) { visit_thing linked_thing }

    it "can remove link to tag" do
      expect(ThingTag.where(:id=>linked_tag.id)).to exist
      within ("sd-thing-editor .thing-form") do
        expect(page).to have_css(".thing-tags ul li",:text=>displayed_name(linked_tag))

        #delete the link
        within(".thing-tags ul li", :text=>displayed_name(linked_tag)) do
          find_field("tag-delete").set(true)
        end
        button = page.has_button?("Update Thing") ? "Update Thing" : "Update Tag Links"
        click_button(button)
          # wait for page to refresh
        expect(page).to have_no_button(button)

        #link should no longer be displayed
        expect(page).to have_no_css(".thing-tags ul li",
                                    :text=>displayed_name(linked_tag))
        #link is removed from database
        expect(ThingTag.where(:id=>linked_tag.id)).to_not exist
      end
    end

    it "can remove link with update to thing", :if=>role == Role::ORGANIZER do
      expect(Thing.find(linked_thing.id).name).to eq(linked_thing.name)
      expect(ThingTag.where(:id=>linked_tag.id)).to exist

      within("sd-thing-editor .thing-form") do
        expect(page).to have_css(".thing-tags ul li", :text=>displayed_name(linked_tag))
        expect(page).to have_field("thing-name", :with=>linked_thing.name,:readonly=>false)

        #delete the link while updating thing
        new_name="changed name"
        fill_in("thing-name", :with=>new_name)
        find_field("thing-name", :with=>new_name)
        within(".thing-tags ul li", :text=>displayed_name(linked_tag)) do
          find_field("tag-delete").set(true)
        end
        #save_and_open_page
        click_button("Update Thing",:wait=>5)

        # wait for page to refresh
        expect(page).to have_button("Update Thing", :disabled=>true)

        #link should no longer be displayed
        expect(page).to have_no_css(".thing-tags ul li",
                                    :text=>displayed_name(linked_tag))
        #name should be updated
        expect(page).to have_no_field("thing-name", :with=>linked_thing.name)
        expect(page).to have_field("thing-name", :with=>new_name,:visible=>false)
        #link is removed from database
        expect(ThingTag.where(:id=>linked_tag.id)).to_not exist
        expect(Thing.find(linked_thing.id).name).to eq(new_name)
      end
    end


    it "update disabled until dirty select", :if=> role==Role::ORGANIZER do
      within("sd-thing-editor .thing-form") do
        expect(page).to have_button("Update Thing", :disabled=>true)
        expect(page).to have_no_button("Update Tag Links")

        #editing only a link causes only the link update to be enabled
        within(".thing-tags ul li", :text=>displayed_name(linked_tag)) do
          find_field("tag-delete").set(true)
        end
        expect(page).to have_no_button("Update Thing")
        expect(page).to have_button("Update Tag Links", :disabled=>false)

        #editing name causes entire object update to be enabled
        fill_in("thing-name", :with=>"new name")
        expect(page).to have_button("Update Thing", :disabled=>false)
        expect(page).to have_no_button("Update Tag Links")
      end
    end
  end

  shared_examples "cannot remove link" do
    before(:each) { visit_thing linked_thing }
    it "cannot select link to delete" do
      within("sd-thing-editor") do
        expect(page).to have_css(".thing-form")
        expect(page).to have_no_field("tag-delete")
      end
    end

    it "does not display update (links) button" do
      within("sd-thing-editor") do
        expect(page).to have_css(".thing-form")
        expect(page).to have_no_button("Update Tag Links")
        expect(page).to have_no_button("Update Thing")
      end
    end
  end



  context "anonymous" do
    it_behaves_like "can get links"
    it_behaves_like "cannot create link"
    # it_behaves_like "cannot edit link"
    it_behaves_like "cannot remove link"
  end
  context "authenticated" do
    before(:each) { login authenticated }
    it_behaves_like "can get links"
    it_behaves_like "cannot create link"
    # it_behaves_like "cannot edit link"
    it_behaves_like "cannot remove link"
  end
  context "alt member" do
    before(:each) { login alt_member }
    it_behaves_like "can get links"
    it_behaves_like "cannot create link"
    # it_behaves_like "cannot edit link"
    it_behaves_like "cannot remove link"
  end
  context "member" do
    before(:each) { login member }
    it_behaves_like "can get links"
    it_behaves_like "can create links"
    # it_behaves_like "cannot edit link"
    it_behaves_like "cannot remove link"
  end
  context "organizer" do
    before(:each) { login organizer }
    it_behaves_like "can get links"
    it_behaves_like "can create links"
    it_behaves_like "can edit link"
    it_behaves_like "can remove link", Role::ORGANIZER
  end
  context "admin" do
    before(:each) { login admin }
    it_behaves_like "can get links"
    it_behaves_like "cannot create link"
    # it_behaves_like "cannot edit link"
    it_behaves_like "can remove link", Role::ADMIN
  end
end
