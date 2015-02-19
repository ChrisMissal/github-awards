class RepositoryFillWorker
  include Sidekiq::Worker

  def perform(filepath)
    event_stream = File.read(filepath); 0
    Models::StreamParser.new(event_stream).parse do |event|
      repo = Repository.where(:user_id => event["a_repository_owner"], :name => event["a_repository_name"]).first
      if repo
        repo.forked ||= event["a_repository_fork"]
        repo.stars ||= event["a_repository_watchers"]
        repo.language ||= event["a_repository_language"]
        repo.processed = true
        repo.save!
      end
    end
  end
end