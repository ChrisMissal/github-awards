require "csv"

namespace :github_archive_crawler do
  
  desc "Parse all github archive users"
  task parse_users: :environment do
    event_stream = File.read("ressources/users.json"); 0
    puts "Start parsing"
    Tasks::UserImporter.new.parse_stream(event_stream)
  end
  
  task crawl_users: :environment do
    puts "Start crawling"
    since = User.last.try(:github_id).try(:to_s) || "0"
    Tasks::UserImporter.new.crawl_github_users(since)
  end
  
  
  task crawl_repos: :environment do
    client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN2"])
    puts "Start crawling repos"
    start_id = Repository.maximum(:github_id)
    since = start_id
    
    loop do
      begin
        found_repos = client.all_repositories(:since => since)
        puts "found #{found_repos.size} repos starting at #{since}"
        found_repos.each do |repo|
          RepositoryWorker.perform_async(repo.to_hash.to_json)
        end
        since = found_repos.last.id
        break if found_repos.size < 100# || since >= 28709353
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
  
  
  task search_not_found_location: :environment do
    User.select("id, location").where("(location IS NOT NULL) AND (location != '') AND ((city IS NULL) OR (city = '')) AND location NOT IN (?)", $redis.smembers("location_error")).each do |user|
      GeocoderWorker.perform_async(user.location)
    end
    # not_found = $redis.smembers("location_error")
    # not_found.each do |location|
    #   GeocoderWorker.perform_async(location)
    # end
  end
  
  task update_locations: :environment do
    iterator=9215
    loop do
      puts "current iterator = #{iterator}"
      result = $redis.hscan("location", iterator)
      iterator = result[0]
      
      result[1].each do |hash|
        location = hash[0]
        geocoded = eval(hash[1])
        puts "updating location : #{location} with : #{geocoded[:city].downcase}, #{geocoded[:country].downcase}"
        User.where("location = '#{location.downcase.gsub("'", "''")}'").update_all(:city => geocoded[:city].downcase, :country => geocoded[:country].downcase, :processed => true)
      end
      
      break if iterator.to_i == 0
    end
  end
  
  
  task set_country_city_from_location: :environment do
    not_found = $redis.smembers("location_error")
    not_found_google = $redis.smembers("location_error_google")
      
    User.select(:location).where("location IS NOT NULL AND (CITY IS NULL AND COUNTRY IS NULL)").group(:location).each do |user|
      location = user.location
      
      next if not_found.include?(location) || not_found_google.include?(location)
      
      begin 
        result = get_address_from_openstreepmap(location)
        #result = get_address_from_googlemap(location) if result.nil?
        if result
          User.where("LOWER(location) = '#{location.downcase.gsub("'", "''")}'").update_all(:city => result[:city], :country => result[:country])
          puts "updating users with location #{location} to city : #{result[:city]} , country : #{result[:country]}"
        else
          puts "No city found for #{location}"
          $redis.sadd("location_error", location)
        end
      rescue Errno::ECONNRESET => e
        puts e
        sleep 1
      rescue JSON::ParserError => e
        puts e
        sleep 1
      end
    end
  end
  
  def get_address_from_openstreepmap(location)
    response = HTTParty.get("http://nominatim.openstreetmap.org/search?q=#{URI.encode(location)}&format=json&accept-language=en-US&addressdetails=1")
    return if response.nil?
    
    result = JSON.parse(response.body)
    place = result.select {|r| ["suburb", "residential", "city", "town", "village"].include?(r["type"]) }.first
    if place
      return {:city => place["address"]["city"], :country => place["address"]["country"]}
    else
      return nil
    end
  end
  
  def get_address_from_googlemap(location)
    
  end
  
  task get_organization: :environment do
    client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN2"])
    $redis.smembers("user_update_error").each do |user_login|
      event = client.user user_login
      User.create(:github_id => event["id"],
        :login => event["login"], 
        :name => event["name"], 
        :mail => event["mail"], 
        :company => event["company"], 
        :blog => event["blog"], 
        :gravatar_url => event["avatar_url"], 
        :location => event["location"],
        :organization => event["type"]=="Organization")
      $redis.srem("user_update_error", user_login)
    end
    
    
    start_date=DateTime.parse("2008-01-01")
    loop do
      search_date = Time.at(start_date.to_i).strftime("%Y-%m-%d")
      puts "searching organization created #{search_date}"
      
      i=0
      loop do
        response = HTTParty.get("https://api.github.com/search/users?access_token=#{ENV["GITHUB_TOKEN"]}&page=#{i}&per_page=100&q=type:Organization+created:#{search_date}")
        results = JSON.parse(response.body)["items"]
        break if results.nil?
        
        results.each do |user|
          UserUpdateWorker.perform_async(user["login"], {"organization" => (user["type"]=="Organization")}.to_json)
        end
        i+=1
        break if results.count < 100
      end
      
      break if start_date >= Time.now
      start_date+=1.day
    end
  end
end