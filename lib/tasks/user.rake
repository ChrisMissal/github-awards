namespace :user do
  desc "Parse all github archive users from big query results"
  task parse_users: :environment do
    event_stream = File.read("ressources/users.json"); 0
    puts "Start parsing"
    Tasks::UserImporter.new.crawl_github_users(since)
  end
  
  desc "Crawl github API for users"
  task crawl_users: :environment do
    puts "Start crawling"
    since = User.last.try(:github_id).try(:to_s) || "0"
    Tasks::UserImporter.new.crawl_github_users(since)
  end
end