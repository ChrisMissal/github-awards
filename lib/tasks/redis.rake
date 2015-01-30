namespace :redis do
  
  task parse_repos: :environment do
    (98..247).each do |i| 
      filename = "ressources/repos_all000000000#{format('%03d', i)}.json"
      event_stream = File.read(filename); 0
      
      puts "Start parsing #{filename}"
      
      i = 0
      start_time = Time.now.to_i
      Yajl::Parser.parse(event_stream) do |event|
        merge_repo(event)
        i+=1
        if i%1000==0
          puts "created #{i} repos in #{start_time - Time.now.to_i}" 
          start_time = Time.now.to_i
        end
      end
    end
  end
  
  
  task parse_users: :environment do
    filename = "ressources/users.json"
    event_stream = File.read(filename); 0
    
    puts "Start parsing #{filename}"
    
    i = 0
    Yajl::Parser.parse(event_stream) do |event|
      merge_user(event)
      i+=1
      puts "created #{i} users"  if i%1000==0
    end
  end
  
  task fill_repos_with_redis: :environment do
    i = 0
    Repository.where(:processed => false).find_each do |repo|
      begin
        repo_infos = $redis.get("repo_url:https://github.com/#{repo.user_id}/#{repo.name}") || ""
        #puts "updating repo #{repo.name} with #{repo_infos}"
        RepositoryFillWorker.perform_async(repo.id, repo_infos)
        puts "filled #{i} repos" if i%1000==0
        i+=1
        #slow down the process so that the redis queue doesn't get filled with millions of jobs
        sleep 0.0027
      rescue Redis::TimeoutError => e
        puts e
        sleep 1
      end
    end
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