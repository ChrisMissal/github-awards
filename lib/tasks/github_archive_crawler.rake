require "csv"

namespace :github_archive_crawler do
  
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
  
  
end