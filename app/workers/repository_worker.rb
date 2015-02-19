class RepositoryWorker
  include Sidekiq::Worker

  def perform(event)
    event = JSON.parse(event)
    Repository.create(:github_id => event["id"],
        :name => event["name"], 
        :user_id => event["owner"],
        :forked => event["fork"]
  end
end