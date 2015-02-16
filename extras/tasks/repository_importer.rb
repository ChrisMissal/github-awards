class Tasks::RepositoryImporter
  def parse_stream(event_stream)
    Models::StreamParser.new(event_stream).parse do |event|
      RepositoryWorker.perform_async(event)
    end
  end
  
  def crawl_github_repos(since)
    client = Models::GithubClient.new(ENV["GITHUB_TOKEN"])
    client.on_found_object = lambda do |repo| 
      RepositoryWorker.perform_async(repo.to_hash)
    end
    
    client.on_too_many_requests = lambda do |user|
      sleep 10
      return nil
    end
    
    client.perform(:all_repositories, since)
  end
end