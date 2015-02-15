require 'yajl'

class Tasks::UserImporter
  
  def parse_stream(event_stream)
    i = 0
    Yajl::Parser.parse(event_stream) do |event|
      UserWorker.perform_async(event)
      i+=1
      puts "created #{i} users" if i%1000==0
    end
  end
  
  def crawl_github_users(since)
    client = Tasks::GithubUserClient.new
    loop do
      found_users = client.next(since)
      puts "found #{found_users.size} users starting at #{since}"
      found_users.each do |user|
        UserWorker.perform_async(user.to_hash)
      end
      since = found_users.last[:id]
      break if found_users.size < client.max_list_size
    end
  end
end