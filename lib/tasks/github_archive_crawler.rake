require 'yajl'

namespace :github_archive_crawler do
  desc "Parse all github archive users"
  task parse_users: :environment do
    event_stream = File.read("ressources/users.json"); 0
    
    puts "Start parsing"
    
    time = DateTime.now
    i = 0
    Yajl::Parser.parse(event_stream) do |event|
      UserWorker.perform_async(event)
      i+=1
      puts "created #{i} users" if i%1000==0
    end
    
    puts "Done : #{DateTime.now - time}"
  end
  
  task parse_repos: :environment do
    event_stream = File.read("ressources/repos.json"); 0
    
    puts "Start parsing"
    
    time = DateTime.now
    i = 0
    Yajl::Parser.parse(event_stream) do |event|
      RepositoryWorker.perform_async(event)
      i+=1
      puts "created #{i} repositories" if i%1000==0
    end
    
    puts "Done : #{DateTime.now - time}"
  end
end
