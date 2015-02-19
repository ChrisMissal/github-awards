class UserWorker
  include Sidekiq::Worker

  def perform(event)
    event = JSON.parse(event)
    User.create(:github_id => event["id"],
        :login => event["login"], 
        :name => event["name"], 
        :email => event["email"], 
        :company => event["company"], 
        :blog => event["blog"], 
        :gravatar_url => event["avatar_url"], 
        :location => event["location"],
        :organization => event["type"]=="Organization")
  end
end