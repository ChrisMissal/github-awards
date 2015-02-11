namespace :export do
  
  desc "Export language list to JSON"
  task languages: :environment do
    File.open(Rails.root.join('app', 'assets', 'javascripts', 'languages.json'), 'w') do |f|
      languages = LanguageRank.select(:language).order("language ASC").distinct.map{ |l| l.language}.to_a
      new_positions = ["javascript", "ruby", "objective-c", "python", "java", "c#", "php", "swift", "shell", "scala", "clojure"]
      new_positions.each_with_index do |lang, new_pos|
        old_pos = languages.index(lang)
        languages[old_pos], languages[new_pos] = languages[new_pos], languages[old_pos]
      end
      f.puts languages.to_json
    end
  end
  
  desc "Export city list to JSON"
  task cities: :environment do
    File.open(Rails.root.join('app', 'assets', 'javascripts', 'cities.json'), 'w') do |f|
      cities = LanguageRank.select(:city).where("city IS NOT NULL").order("city ASC").distinct
      cities = cities.map{ |l| l.city.gsub(/[^0-9A-Za-z ]/, '').strip.capitalize}.to_a.reject(&:empty?)
      f.puts cities.to_json
    end
  end
  
end