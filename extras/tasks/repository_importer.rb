class Tasks::RepositoryImporter
  def crawl_github_repos(since)
    client = Models::GithubClient.new(ENV["GITHUB_TOKEN"])
    client.on_found_object = lambda do |repo| 
      repo = repo.to_hash.with_indifferent_access
      repo[:owner] = repo[:owner][:login]
      RepositoryWorker.perform_async(repo.to_json)
    end
    
    client.on_too_many_requests = lambda do |error|
      Rails.logger.error error
      sleep 10
      return nil
    end
    
    client.perform(:all_repositories, since)
  end
  
  
  def parse_streams
    (0..247).each do |i| 
      filename = "ressources/repos_all000000000#{format('%03d', i)}.json"
      event_stream = File.read(filename); 0
      
      Rails.logger.info "Start parsing #{filename}"
      Models::StreamParser.new(event_stream).parse do |event|
        merge_repo(event)
      end
    end
  end
  
  #a refactorer => ne pas merger les repo, garder celui avec le max de stars (ou la date la plus récente ?)
  def merge_repo(event)
    repo = $redis.get("repo_url:"+event["a_repository_url"])
    infos = event.select {|k, v| ["a_repository_watchers", "a_repository_language", "a_repository_fork"].include?(k)}

    if repo
      if !repo["a_repository_fork"] && event["a_repository_fork"]
        infos["a_repository_fork"] = true
      end
      
      if repo["a_repository_watchers"] < event["a_repository_watchers"]
        infos["a_repository_watchers"] = event["a_repository_watchers"]
      end
      
      if repo["a_repository_language"].blank? && event["a_repository_language"].present?
        infos["a_repository_language"] = event["a_repository_language"]
      end
    end
    $redis.set("repo_url:"+event["a_repository_url"], infos.to_json)
  end
end