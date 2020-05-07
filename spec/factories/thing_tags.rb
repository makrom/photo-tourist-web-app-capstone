FactoryGirl.define do
  factory :thing_tag do
    creator_id 1

    after(:build) do |link|
      link.tag=build(:tag) unless link.tag
    end
  end
end
