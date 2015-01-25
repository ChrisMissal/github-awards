class RepositoryWorker
  include Sidekiq::Worker

  def perform(event)
    Repository.create!(:created_at => event["created_at"],
        :name => event["name"], 
        :user_id => event["owner"], 
        :stars => event["stars"], 
        :organization => event["organization"], 
        :language => event["language"])
  end
end