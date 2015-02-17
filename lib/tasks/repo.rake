namespace :repo do
  desc "Crawl github API for repositories"
  task crawl_repos: :environment do
    puts "Start crawling"
    since = Repository.maximum(:github_id) || "0"
    Tasks::RepositoryImporter.new.crawl_github_repos(since)
  end
end