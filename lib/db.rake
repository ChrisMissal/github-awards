namespace :db do
  
  task extract_cities_and_countries: :environment do
    cities = LanguageRank.select("city").distinct
    File.open("tmp/cities.json", "w") do |f|
      f.puts cities.to_json
    end
    
    countries = LanguageRank.select("country").distinct
    File.open("tmp/countries.json", "w") do |f|
      f.puts countries.to_json
    end
  end
end