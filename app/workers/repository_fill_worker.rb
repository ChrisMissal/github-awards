class RepositoryFillWorker
  include Sidekiq::Worker

  def perform(repo_id, repo_infos)
    repo = Repository.find(repo_id)
    if repo_infos != ""
      infos = JSON.parse(repo_infos)
      repo.update_columns(:stars => infos["a_repository_watchers"] || 0, 
        :language => infos["a_repository_language"], 
        :forked => infos["a_repository_fork"],
        :processed => true)
    else
      repo.update_column(:processed, true)
    end
  end
end