namespace :redis do
  
  desc "Clean sidekiq jobs"
  task clean_sidekiq: :environment do
    require "sidekiq/api"
    Sidekiq::Queue.new.clear
    Sidekiq::RetrySet.new.clear
  end
  
  
  task parse_users: :environment do
    filename = "ressources/users.json"
    event_stream = File.read(filename); 0
    
    Tasks::UserImporter.new.parse_stream(event_stream)
  end
  
  
  task fill_user_with_redis: :environment do
    i = 0
    User.where(:processed => false).find_each do |user|
      begin
        user_infos = $redis.get("user_login:#{user.login}") || ""
        #puts "updating repo #{repo.name} with #{repo_infos}"
        UserFillWorker.perform_async(user.id, user_infos)
        puts "filled #{i} users" if i%1000==0
        i+=1
        #slow down the process so that the redis queue doesn't get filled with millions of jobs
        sleep 0.0019
      rescue Redis::TimeoutError => e
        puts e
        sleep 1
      end
    end
  end
end