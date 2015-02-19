require 'rails_helper'

describe Tasks::UserImporter do
  # describe "parse_stream" do
  #   before(:each) do
  #     event_stream = File.read("spec/fixtures/tasks/repos.json");
  #     Tasks::RepositoryImporter.new.parse_stream(event_stream)
  #   end
    
  #   it "creates user" do
  #     Repository.count.should == 2
  #   end
    
  #   it "sets values" do
  #     u = Repository.where(:name => "sdfsdfsdfsf").first
  #     u.user_id.should == "liuyaruzuzhi01"
  #     u.stars.should == 0
  #     u.organization.should == "liuyaruzuzhi01"
  #   end
  # end
  
  describe "crawl_github_repos" do
    it "creates the repo" do
      stub_response = JSON.parse(File.read("spec/fixtures/github_api_repo.json"))
      Octokit::Client.any_instance.stubs(:all_repositories).returns(stub_response)
      Tasks::RepositoryImporter.new.crawl_github_repos("0")
      Repository.count.should == 1
    end
    
    it "iterates while max repos is reached" do
      Octokit::Client.any_instance.stubs(:all_repositories)
      .returns([{"owner" => "foo1", "name" => "bar1", "id" => 0}, {"owner" => "foo2", "name" => "bar2", "id" => 1}])
      .then.returns([{"owner" => "foo3", "name" => "bar3", "id" => 2}])
      Models::GithubClient.any_instance.stubs(:max_list_size).returns(2)
      Tasks::RepositoryImporter.new.crawl_github_repos("0")
      Repository.count.should == 3
    end
    
    context "network error" do
      it "continues crawling" do
        Octokit::Client.any_instance.stubs(:all_repositories).raises(Errno::ETIMEDOUT)
        .then.returns([{:owner => "foo3", "name" => "bar3", :id => 2}])
        Tasks::RepositoryImporter.new.crawl_github_repos("0")
        Repository.count.should == 1
      end
    end
  end
end

