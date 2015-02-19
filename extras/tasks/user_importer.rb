class Tasks::UserImporter
  def parse_stream(event_stream)
    Models::StreamParser.new(event_stream).parse do |event|
      merge_user(event)
    end
  end
  
  def crawl_github_users(since)
    client = Models::GithubClient.new(ENV["GITHUB_TOKEN"])
    client.on_found_object = lambda do |user| 
      User.create(:github_id => user["id"],
        :login => user["login"],
        :gravatar_url => user["avatar_url"],
        :organization => user["type"]=="Organization")
    end
    
    client.on_too_many_requests = lambda do |error|
      Rails.logger.error error
      sleep 10
      return nil
    end
    
    client.perform(:all_users, since)
  end
  
  def merge_user(event)
    #ignore lines with only login
    if event.keys == ["login"]
      return
    end
    
    user = $redis.get("user_login:"+event["login"])
    if user
      user = JSON.parse(user)
      event["name"] ||= user["name"]
      event["company"] ||= user["company"]
      event["location"] ||= user["location"]
      event["blog"] ||= user["blog"]
      event["email"] ||= user["email"]
    end
    $redis.set("user_login:"+event["login"], event.to_json)
  end
  
end