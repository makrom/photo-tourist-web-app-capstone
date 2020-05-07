class Thing < ActiveRecord::Base
  include Protectable
  validates :name, :presence=>true

  has_many :thing_images, inverse_of: :thing, dependent: :destroy
  has_many :thing_tags, inverse_of: :thing, dependent: :destroy

  scope :not_linked, ->(image) { where.not(:id=>ThingImage.select(:thing_id)
                                                          .where(:image=>image)) }
  scope :not_linked_tags, ->(tag) { where.not(:id=>ThingTag.select(:thing_id)
                                                          .where(:tag=>tag)) }
end
