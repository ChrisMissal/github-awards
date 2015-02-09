require 'tor'
require 'benchmark'

class GoogleMapRateLimitExceeded < StandardError 
  attr :control_port
  
  def initialize(control_port)
    @control_port = control_port
  end
end

class GoogleMap
  def initialize
    @agent = Mechanize.new
    @agent.set_proxy("127.0.0.1", 5566)
  end
  
  def call(location)
    require 'mechanize'
    page = @agent.get("https://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(location)}")
    response = page.content
    result = JSON.parse(response)
    if result["status"]=="OVER_QUERY_LIMIT"
      raise GoogleMapRateLimitExceeded.new("")
    end
    
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
end

class GeocoderWorker
  include Sidekiq::Worker
  
  def perform(location)
    begin
      result = GoogleMap.new.call(location)
            
      if result
        # puts Benchmark.measure {
        #   User.where("location = '#{location.downcase.gsub("'", "''")}'").update_all(:city => result[:city].downcase, :country => result[:country].downcase, :processed => true)
        # }
        #
        $redis.hset("location", location.downcase.gsub("'", "''"), {:city => result[:city], :country => result[:country]})
        puts "updating users with location #{location} to city : #{result[:city]} , country : #{result[:country]}"
      else
        # puts Benchmark.measure {
        #   User.where("location = '#{location.downcase.gsub("'", "''")}'").update_all(:processed => true)
        # }
        #
        $redis.sadd("location_error", location)
        puts "No city found for #{location}"
      end
    rescue GoogleMapRateLimitExceeded => e
      puts e
      
      #Switch IP
      # Tor::Controller.connect(:port => e.control_port) do |tor|
      #   tor.authenticate("password")
      #   tor.signal("newnym")
      #   sleep 10
      # end
      sleep 1
    rescue JSON::ParserError => e
      puts e
    rescue OpenSSL::SSL::SSLError => e
      puts e
    rescue StandardError => e
      puts e
    end
  end
end