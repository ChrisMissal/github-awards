namespace :repo do
  desc "Parse all github archive repositories from big query results"
  task parse_repos: :environment do
    event_stream = File.read("ressources/repos.json"); 0
    puts "Start parsing"
    Tasks::RepositoryImporter.new.parse_stream(event_stream)
  end
  
  desc "Crawl github API for repositories"
  task crawl_repos: :environment do
    puts "Start crawling"
    since = Repository.maximum(:github_id) || "0"
    Tasks::RepositoryImporter.new.crawl_github_repos(since)
  end
end