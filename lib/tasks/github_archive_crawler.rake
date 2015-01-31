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
      begin
        found_users = client.all_users(:since => since)
        puts "found #{found_users.size} users starting at #{since}"
        found_users.each do |user|
          UserWorker.perform_async(user.to_hash)
        end
        since = found_users.last.id
        break if found_users.size < 100
      rescue Octokit::TooManyRequests => e
        puts e
        sleep 10
      rescue Errno::ETIMEDOUT => e
        puts e
        sleep 1
      rescue Errno::ENETDOWN => e
        puts e
        sleep 1
      end
    end
  end
  
  
  task crawl_repos: :environment do
    client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN"])
    puts "Start crawling repos"
    start_id = 27941122#Repository.maximum(:github_id)
    since = start_id
    
    loop do
      begin
        found_repos = client.all_repositories(:since => since)
        puts "found #{found_repos.size} repos starting at #{since}"
        found_repos.each do |repo|
          RepositoryWorker.perform_async(repo.to_hash.to_json)
        end
        since = found_repos.last.id
        break if found_repos.size < 100 || since >= 28709353
        #sleep 0.25
      rescue Errno::ETIMEDOUT => e
        puts e
        sleep 1
      rescue Errno::ENETDOWN => e
        puts e
        sleep 1
      end
    end
  end
  
  task crawl_repos2: :environment do
    client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN2"])
    puts "Start crawling repos"
    start_id = 29492537#Repository.maximum(:github_id)+1000000
    since = start_id
    
    loop do
      begin
        found_repos = client.all_repositories(:since => since)
        puts "found #{found_repos.size} repos starting at #{since}"
        found_repos.each do |repo|
          RepositoryWorker.perform_async(repo.to_hash.to_json)
        end
        since = found_repos.last.id
        break if found_repos.size < 100 || since >= 29992178
        #sleep 0.25
      rescue Errno::ETIMEDOUT => e
        puts e
        sleep 1
      rescue Errno::ENETDOWN => e
        puts e
        sleep 1
      end
    end
  end
  
  # task parse_repos: :environment do
  #   event_stream = File.read("ressources/repos.json"); 0
    
  #   puts "Start parsing"
    
  #   time = DateTime.now
  #   i = 0
  #   Yajl::Parser.parse(event_stream) do |event|
  #     RepositoryWorker.perform_async(event)
  #     i+=1
  #     puts "created #{i} repositories" if i%1000==0
  #   end
    
  #   puts "Done : #{DateTime.now - time}"
  # end
  
  # task import_avatars: :environment do
  #   not_found = File.readlines("tmp/errors.txt").each {|l| l.chomp!}
  #   client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN"])
  #   User.where("gravatar_url IS NULL OR gravatar_url = ''").where("login NOT IN (?)", not_found).find_each do |user|
  #     begin
  #       github_user = client.user user.login
  #       user.update_attributes(:gravatar_url => github_user.avatar_url)
  #       puts "updated #{user.login} with avatar_url : #{github_user.avatar_url}"
  #     rescue Octokit::NotFound => e
  #       puts e
  #       File.open("tmp/errors.txt", "a+") do |f|
  #         f.puts user.login
  #       end
  #     end
  #   end
  # end
  
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
  
  task create_country_db: :environment do
    file = File.read("ressources/country.txt", encoding: "ISO8859-1"); 0
    country_array = file.split("\n")[1..-1]; 0
    
    cities = country_array.map do |country| 
      attributes = country.delete("\r").split("\t")
      puts "set #{attributes[1].downcase} = #{attributes[3].downcase}"
      City.where(:country => attributes[1].downcase).update_all(:country_full_name => attributes[3].downcase)
    end; 0
  end
  
  
  task set_country_city_from_location: :environment do
    #User.select(:location).distinct
    #location = URI.encode(User.where("location IS NOT NULL").first.location)
    User.select(:location).where("location IS NOT NULL AND (CITY IS NULL AND COUNTRY IS NULL)").group(:location).each do |user|
      location = user.location
      
      not_found = $redis.smembers("location_error")
      next if not_found.include?(location)
      
      begin 
        result = get_address_from_openstreepmap(location)
        result = get_address_from_googlemap(location) if result.nil?
      rescue Errno::ECONNRESET => e
        puts e
      end
      
      if result
        count = User.where("LOWER(location) = '#{location.downcase.gsub("'", "''")}'").update_all(:city => result[:city], :country => result[:country])
        puts "updating users with location #{location} to city : #{result[:city]} , country : #{result[:country]}"
      else
        puts "No city found for #{location}"
        $redis.sadd("location_error", location)
      end
    end
  end
  
  def get_address_from_openstreepmap(location)
    response = HTTParty.get("http://nominatim.openstreetmap.org/search?q=#{URI.encode(location)}&format=json&accept-language=en-US&addressdetails=1")
    result = JSON.parse(response.body)
    place = result.select {|r| ["suburb", "residential", "city", "town", "village"].include?(r["type"]) }.first
    if place
      return {:city => place["address"]["city"], :country => place["address"]["country"]}
    else
      return nil
    end
  end
  
  def get_address_from_googlemap(location)
    response = HTTParty.get("https://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(location)}")
    result = JSON.parse(response.body)
    address_components = result.try(:[], "results").try(:first).try(:[], "address_components")
    return if address_components.nil?
      
    city = address_components.select { |r| r["types"].include?("locality")}.first
    country = address_components.select { |r| r["types"].include?("country")}.first
    if city && country
      return {:city => city["long_name"], :country => country["long_name"]}
    else
      return
    end
  end
  
  # task call_github_api: :environment do
  #   require 'net/telnet'
    
  #   original_ip = Mechanize.new.get("http://bot.whatismyipaddress.com").content
  #   puts "original IP is : #{original_ip}"

  #   TCPSocket::socks_server = "127.0.0.1"
  #   TCPSocket::socks_port = "50001"

  #   tor_control_port_start = 9050
  #   client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN"])
  #   users = client.all_users
  # end
end
