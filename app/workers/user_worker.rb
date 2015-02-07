class UserWorker
  include Sidekiq::Worker

  def perform(event)
    User.create(:github_id => event["id"],
        :login => event["login"], 
        :name => event["name"], 
        :mail => event["mail"], 
        :company => event["company"], 
        :blog => event["blog"], 
        :gravatar_url => event["avatar_url"], 
        :location => event["location"],
        :organization => event["type"]=="Organization")
  end
end