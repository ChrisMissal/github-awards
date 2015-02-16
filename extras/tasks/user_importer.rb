class Tasks::UserImporter
  def parse_stream(event_stream)
    Models::StreamParser.new(event_stream).parse do |event|
      UserWorker.perform_async(event)
    end
  end
  
  def crawl_github_users(since)
    client = Tasks::GithubClient.new(ENV["GITHUB_TOKEN"])
    client.on_found_object = lambda do |user| 
      UserWorker.perform_async(user.to_hash)
    end
    
    client.on_too_many_requests = lambda do |user|
      sleep 10
      return nil
    end
    
    client.perform(:all_users, since)
  end
end