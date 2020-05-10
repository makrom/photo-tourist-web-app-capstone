module SubjectsUiHelper
  def visit_images images
    visit "#{ui_path}/#/images/"
    within("sd-image-selector") do
      expect(page).to have_css(".image-list")
      expect(page).to have_css(".image-list li",:count=>images.count,:wait=>5)
    end
  end

  def visit_tags tags
    visit "#{ui_path}/#/tags/"
    within("sd-tag-selector") do
      expect(page).to have_css(".tag-list")
      expect(page).to have_css(".tag-list li",:count=>tags.count,:wait=>5)
    end
  end

  def get_linkables link_item #image  # it seems to be one for two: images and tags
    things=ThingPolicy::Scope.new(current_user, Thing.not_linked(link_item)).user_roles(true,false)
    things=ThingPolicy.merge(things)
  end

  def image_editor_loaded! image, expected_linkables=nil
    within("sd-image-editor .image-form") do
      expect(page).to have_css("span.image_id",:text=>image.id,:visible=>false)
      expect(page).to have_css(".image-controls")
      expect(page).to have_css("ul.image-things li span.thing_id",
                              :visible=>false,
                              :count=>ThingImage.where(:image=>image).count,
                              :wait=>5)
    end
    expected_linkables ||= get_linkables(image).size
    if expected_linkables && logged_in?
      expect(page).to have_css(".link-things select option", :count=>expected_linkables)
    end
  end

  def tag_editor_loaded! tag, expected_linkables=nil
    within("sd-tag-editor .tag-form") do
      expect(page).to have_css("span.tag_id",:text=>tag.id,:visible=>false)
      expect(page).to have_css(".tag-controls")
      expect(page).to have_css("ul.tag-things li span.thing_id",
                              :visible=>false,
                              :count=>ThingTag.where(:tag=>tag).count,
                              :wait=>5)
    end
    expected_linkables ||= get_linkables(tag).size
    if expected_linkables && logged_in?
      expect(page).to have_css(".link-things select option", :count=>expected_linkables)
    end
  end

  def visit_image image
    unless page.has_css?("sd-image-editor .image-form span.image_id",
                          :text=>image.id,:visible=>false)
      visit "#{ui_path}/#/images/#{image.id}"
    end
    within("sd-image-editor .image-form") do
      expect(page).to have_css("span.image_id",:text=>image.id,:visible=>false)
      expect(page).to have_css(".image-controls")
    end
  end

  def visit_tag tag
    unless page.has_css?("sd-tag-editor .tag-form span.tag_id",
                          :text=>tag.id,:visible=>false)
      visit "#{ui_path}/#/tags/#{tag.id}"
    end
    within("sd-tag-editor .tag-form") do
      expect(page).to have_css("span.tag_id",:text=>tag.id,:visible=>false)
      expect(page).to have_css(".tag-controls")
    end
  end

  def displayed_caption(image)
    image.caption ? image.caption : "(no caption #{image.id})"
  end

  def displayed_name(tag)
    tag.name ? tag.name : "(no name #{tag.id})"
  end

  def visit_thing thing
    unless page.has_css?("sd-thing-editor .thing-form span.thing_id",
                          :text=>thing.id,:visible=>false)
      visit "#{ui_path}/#/things/#{thing.id}"
    end
    within("sd-thing-editor .thing-form") do
      expect(page).to have_css("span.thing_id",:text=>thing.id,:visible=>false)
    end
  end

  def thing_editor_loaded! thing
    expect(page).to have_css("sd-thing-editor")
    within("sd-thing-editor .thing-form") do
      expect(page).to have_css("span.thing_id",:text=>thing.id,
                                               :visible=>false)
      expect(page).to have_css("ul.thing-images li span.image_id",
                              :visible=>false,
                              :count=>ThingImage.where(:thing=>thing).count,
                              :wait=>5)
      expect(page).to have_css("ul.thing-tags li span.tag_id",
                              :visible=>false,
                              :count=>ThingTag.where(:thing=>thing).count,
                              :wait=>5)
    end
  end

  def visit_things things
    visit "#{ui_path}/#/things/"
    within("sd-thing-selector", :wait=>5) do
      if logged_in?
        expect(page).to have_css(".thing-list")
        expect(page).to have_css(".thing-list li",:count=>things.count, :wait=>5)
      end
    end
  end
end
