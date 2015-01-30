require 'rails_helper'

describe "User" do
  
  describe "new" do
    it { FactoryGirl.build(:user, :login => nil).save.should == false }
    it { FactoryGirl.build(:user).save.should == true }
  end
  
  describe "unique fields" do
    before(:each) do
      FactoryGirl.create(:user, :login => "foo")
    end
    
    it "allows different login" do
      FactoryGirl.build(:user, :login => "bar").save.should == true
    end
    
    it "forbids duplicates login" do
      FactoryGirl.build(:user, :login => "foo").save.should == false
    end
  end
  
end