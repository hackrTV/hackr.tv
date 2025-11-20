FactoryBot.define do
  factory :codex_entry do
    name { "MyString" }
    slug { "MyString" }
    entry_type { "MyString" }
    summary { "MyText" }
    content { "MyText" }
    metadata { "" }
    published { false }
    position { 1 }
  end
end
