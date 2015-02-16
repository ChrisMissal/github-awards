class RepositoryWorker
  include Sidekiq::Worker

  def perform(event)
    Repository.create!(:github_id => event["id"],
        :created_at => event["created_at"],
        :name => event["name"], 
        :user_id => event["owner"], 
        :stars => event["stars"] || 0, 
        :organization => event["organization"], 
        :language => event["language"])
  end
end