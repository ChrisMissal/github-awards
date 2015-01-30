class RepositoryWorker
  include Sidekiq::Worker

  def perform(event)
    event = JSON.parse(event)
    Repository.create(:github_id => event["id"],
        :created_at => event["created_at"],
        :name => event["name"], 
        :user_id => event["owner"][0][1], 
        :stars => event["stars"] || 0, 
        :organization => event["organization"], 
        :language => event["language"])
  end
end