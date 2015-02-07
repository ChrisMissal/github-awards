class UserUpdateWorker
  include Sidekiq::Worker

  def perform(login, hash_values)
    hash_values = JSON.parse(hash_values)
    user = User.where(:login => login).first

    if user.nil?
      $redis.sadd("user_update_error", login)
    else
      user.update_attributes(hash_values)
    end
  end
end