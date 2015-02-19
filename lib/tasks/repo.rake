namespace :repo do
  desc "Crawl github API for repositories"
  task crawl: :environment do
    Rails.logger.info "Start crawling"
    since = Repository.maximum(:github_id) || "0"
    Tasks::RepositoryImporter.new.crawl_github_repos(since)
  end
  
  desc "Get latest infos for each repos"
  task parse_repos: :environment do
    Tasks::RepositoryImporter.new.parse_streams
  end
  
  # task fill_repos_with_redis: :environment do
  #   i = 0
  #   Repository.where(:processed => false).find_each do |repo|
  #     begin
  #       repo_infos = $redis.get("repo_url:https://github.com/#{repo.user_id}/#{repo.name}") || ""
  #       #puts "updating repo #{repo.name} with #{repo_infos}"
  #       RepositoryFillWorker.perform_async(repo.id, repo_infos)
  #       puts "filled #{i} repos" if i%1000==0
  #       i+=1
  #       #slow down the process so that the redis queue doesn't get filled with millions of jobs
  #       sleep 0.0018
  #     rescue Redis::TimeoutError => e
  #       puts e
  #       sleep 1
  #     end
  #   end
  # end
end