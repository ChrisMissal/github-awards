require 'rails_helper'

describe Tasks::UserImporter do
  describe "parse_stream" do
    before(:each) do
      event_stream = File.read("spec/fixtures/tasks/users.json");
      Tasks::UserImporter.new.parse_stream(event_stream)
    end
    
    it "creates user" do
      User.count.should == 2
    end
    
    it "sets values" do
      u = User.where(:login => "Amoysec").first
      u.name.should == "foo"
      u.company.should == "bar"
      u.location.should == "SF"
      u.blog.should == "www.foo.bar"
      u.email.should == "foo@bar.com"
    end
  end
  
  describe "crawl_github_users" do
    it "iterates while max users is reached" do
      Octokit::Client.any_instance.stubs(:all_users)
      .returns([{:login => "foo1", :id => 0}, {:login => "foo2", :id => 1}])
      .then.returns([{:login => "foo3", :id => 2}])
      Models::GithubClient.any_instance.stubs(:max_list_size).returns(2)
      Tasks::UserImporter.new.crawl_github_users("0")
      User.count.should == 3
    end
    
    context "network error" do
      it "continues crawling" do
        Octokit::Client.any_instance.stubs(:all_users).raises(Errno::ETIMEDOUT)
        .then.returns([{:login => "foo", :id => 0}])
        Tasks::UserImporter.new.crawl_github_users("0")
        User.count.should == 1
      end
    end
  end
end