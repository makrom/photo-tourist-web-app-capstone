FactoryGirl.define do
  factory :tag do
    name {Faker::Commerce.department}
    creator_id 1

    trait :with_roles do
      after(:create) do |tag|
        Role.create(:role_name=>Role::ORGANIZER,
                    :mname=>Tag.name,
                    :mid=>tag.id,
                    :user_id=>tag.creator_id)
      end
    end
  end
end
