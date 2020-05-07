class ThingTag < ActiveRecord::Base
  belongs_to :thing
  belongs_to :tag

  validates :tag, :thing, presence: true

  scope :with_name,     ->{ joins(:thing).select("thing_tags.*, things.name as thing_name")}
  scope :with_tag_name, ->{ joins(:tag).select("thing_tags.*, tags.name as tag_name")}
end
