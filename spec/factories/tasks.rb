FactoryBot.define do
  factory :task do
    title { Faker::Lorem.word }
    description { Faker::Lorem.paragraph }
    status { "todo" }
    priority { 1 }
    user
    category
  end
end
