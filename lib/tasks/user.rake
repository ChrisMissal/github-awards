namespace :user do
  desc "Crawl github API for users"
  task crawl_users: :environment do
    puts "Start crawling"
    since = User.last.try(:github_id).try(:to_s) || "0"
    Tasks::UserImporter.new.crawl_github_users(since)
  end
  
  desc "Geocode user locations"
  task :geocode_locations, [:start_date] => :environment do |t, args|
    geocoder = args.geocoder || :googlemap
    
    User.select("id, location").where("(location IS NOT NULL) AND (location != '') AND ((city IS NULL) OR (city = '')) AND location NOT IN (?)", $redis.smembers("location_error")).each do |user|
      GeocoderWorker.perform_async(user.location, geocoder)
    end
  end
end