namespace :rank do
  
  task create: :environment do
    res = ActiveRecord::Base.connection.execute(File.read("sql/rank.sql"))
    
    
    # Repository.select(:language).where("language IS NOT NULL").group(:language).each do |repo|
    #   language = repo.language
    #   User.select(:city).where("city IS NOT NULL").group(:city).each do |user|
    #     city = user.city
    #     country = nil
    #     puts "Compute rank for #{language} in #{city}"
        
    #     total_query = "SELECT count(DISTINCT user_id) "\
    #               "FROM repositories "\
    #               "INNER JOIN users ON repositories.user_id = users.login "\
    #               "WHERE LOWER(repositories.language) = '#{language}' AND LOWER(users.city)='#{city}' AND users.organization=FALSE" \
                  
    #     res = ActiveRecord::Base.connection.execute(total_query)
    #     total = res[0]["count"].to_i
    #     puts "total = #{total}"

        
    #     rank_query = "SELECT users.id AS user_id, sum(stars) + (1.0 - 1.0/count(repositories.id)) AS score, row_number() OVER (ORDER BY sum(stars) DESC) AS rank, count(repositories.id) AS repository_count, sum(stars) AS stars_count "\
    #             "FROM repositories "\
    #             "INNER JOIN users ON repositories.user_id = users.login "\
    #             "WHERE LOWER(repositories.language) = '#{language}' AND LOWER(users.city)='#{city}' AND users.organization=FALSE "\
    #             "GROUP BY user_id, users.id "\
    #             "ORDER BY sum(stars) + (1.0 - 1.0/count(repositories.id)) DESC "\
                
    #     result = ActiveRecord::Base.connection.execute(rank_query)
    #     result.each do |res|
    #       res.merge(city: city, country: country, language: language, top: res["rank"].to_f/total.to_f*100)
    #       LanguageRank.create(res)
    #     end
    #   end
    # end
  end
end