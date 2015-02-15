class Tasks::GithubUserClient
  attr_accessor :max_list_size
  
  def initialize
    @client = Octokit::Client.new(:access_token => ENV["GITHUB_TOKEN"])
    @max_list_size = 100
  end
  
  def next(since)
    begin
      @client.all_users(:since => since)
    rescue Octokit::TooManyRequests => e
      puts e
      sleep 10
    rescue Errno::ETIMEDOUT, Errno::ENETDOWN => e
      puts e
      sleep 1
    end
  end
end