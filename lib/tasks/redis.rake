namespace :redis do
  
  task parse_repos: :environment do
    
    (1..247).each do |i| 
      filename = "ressources/repos_all0000000000#{format('%02d', i)}.json"
      event_stream = File.read(filename); 0
      
      puts "Start parsing #{filename}"
      
      i = 0
      Yajl::Parser.parse(event_stream) do |event|
        merge(event)
        i+=1
        puts "created #{i} repos" if i%1000==0
      end
    end
  end


  def merge(event)
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