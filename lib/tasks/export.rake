namespace :export do
  
  desc "Export language list to JSON"
  task language: :environment do
    File.open(Rails.root.join('app', 'assets', 'javascripts', 'languages.json'), 'w') do |f|
      f.puts LanguageRank.select(:language).order("language ASC").distinct.map{ |l| l.language.capitalize}.to_json
    end
  end
  
  desc "Export city list to JSON"
  task city: :environment do
    File.open(Rails.root.join('app', 'assets', 'javascripts', 'city.json'), 'w') do |f|
      f.puts LanguageRank.select(:city).where("city IS NOT NULL").order("city ASC").distinct.map{ |l| l.city.gsub(/[^0-9A-Za-z ]/, '').capitalize}.to_json
    end
  end
  
end