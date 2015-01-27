require 'yajl'
require "csv"

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
  
  task crawl_users: :environment do
    client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN"])
    puts "Start crawling"
    since = User.last.try(:github_id).try(:to_s) || "0"
    
    loop do
      found_users = client.all_users(:since => since)
      puts "found #{found_users.size} users starting at #{since}"
      found_users.each do |user|
        UserWorker.perform_async(user.to_hash)
      end
      since = found_users.last.id
      break if found_users.size < 100
      sleep 0.5
    end
  end
  
  
  # task crawl_repos: :environment do
  #   client = Octokit::Client.new(:access_token => "")
  #   puts "Start crawling"
  #   since = Repos.last.try(:github_id).try(:to_s) || "0"
    
  #   loop do
  #     found_users = client.all_users(:since => since)
  #     puts "found #{found_users.size} users starting at #{since}"
  #     found_users.each do |user|
  #       UserWorker.perform_async(user.to_hash)
  #     end
  #     since = found_users.last.id
  #     break if found_users.size < 100
  #     sleep 0.5
  #   end
  # end
  
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
  
  task import_avatars: :environment do
    not_found = File.readlines("tmp/errors.txt").each {|l| l.chomp!}
    client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN"])
    User.where("gravatar_url IS NULL OR gravatar_url = ''").where("login NOT IN (?)", not_found).find_each do |user|
      begin
        github_user = client.user user.login
        user.update_attributes(:gravatar_url => github_user.avatar_url)
        puts "updated #{user.login} with avatar_url : #{github_user.avatar_url}"
      rescue Octokit::NotFound => e
        puts e
        File.open("tmp/errors.txt", "a+") do |f|
          f.puts user.login
        end
      end
    end
  end
  
  task create_location_db: :environment do
    file = File.read("ressources/worldcitiespop.txt", encoding: "ISO8859-1"); 0
    city_array = file.split("\n")[1..-1]; 0
    
    puts "start parsing"
    i = 0
    cities = city_array.map do |city| 
      attributes = city.split(",")
      CityWorker.perform_async(attributes)
      
      i+=1
      puts "created #{i} cities" if i%1000==0
      
    end; 0
  end
  
  task call_github_api: :environment do
    require 'net/telnet'
    
    original_ip = Mechanize.new.get("http://bot.whatismyipaddress.com").content
    puts "original IP is : #{original_ip}"

    TCPSocket::socks_server = "127.0.0.1"
    TCPSocket::socks_port = "50001"

    tor_control_port_start = 9050
    client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN"])
    users = client.all_users
    
    
    
    # 2.times do
    #   localhost = Net::Telnet::new("Host" => "localhost", "Port" => "#{tor_control_port_start}", "Timeout" => 10, "Prompt" => /250 OK\n/)
    #   localhost.cmd('AUTHENTICATE ""') { |c| throw "Cannot authenticate to Tor" if c != "250 OK\n" }
    #   localhost.cmd('signal NEWNYM') { |c| throw "Cannot switch Tor to new route" if c != "250 OK\n" }
    #   localhost.close      
    #   sleep 5
      
    #   new_ip = Mechanize.new.get("http://bot.whatismyipaddress.com").content
    #   puts "new IP is #{new_ip}"
    # end
  end
end
