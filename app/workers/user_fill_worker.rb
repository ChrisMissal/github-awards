class UserFillWorker
  include Sidekiq::Worker

  def perform(user_id, user_infos)
    user = User.find(user_id)
    if user_infos != ""
      infos = JSON.parse(user_infos)
      user.update_columns(:mail => infos["email"], 
        :name => infos["name"], 
        :company => infos["company"],
        :blog => infos["blog"],
        :location => infos["location"],
        :processed => true)
    else
      user.update_columns(:processed => true)
    end
  end
end