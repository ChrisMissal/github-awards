FactoryGirl.define do
  factory :language_rank do
    user
    language          "string"
    score             1.0
    rank              2
    repository_count  1
    stars_count       0
  end
end