# encoding: utf-8
require 'rails_helper'

describe UsersController do
  
  let(:user) { FactoryGirl.create(:user, :login => "vdaubry") }
  let(:language_ranks) { FactoryGirl.create_list(:language_rank, 2, :user => user) }
  
  describe "GET show" do
    context "user exists" do
      it "sets user" do
        user
        get :show, :id => "vdaubry"
        assigns(:user).should == user
      end
      
      it "sets language_ranks" do
        language_ranks
        get :show, :id => "vdaubry"
        assigns(:language_ranks).count.should == 2
      end
    end
    
    context "user doesn't exists" do
      it "returns 404" do
        expect {
          get :show, :id => "vdaubry"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
  
  describe "GET search" do
    context "user exists" do
      it "sets user" do
        user
        get :search, :login => "vdaubry"
        assigns(:user).should == user
      end
      
      it "sets language_ranks" do
        language_ranks
        get :search, :login => "vdaubry"
        assigns(:language_ranks).count.should == 2
      end
    end
    
    context "user doesn't exists" do
      it "redirects to users index" do
        get :search, :login => "vdaubry"
        response.should redirect_to(users_path)
      end
    end
  end
  
  describe "GET index" do
    context "has params city and language" do
      it "keeps params" do
        get :index, :city => "Paris", :language => "Ruby"
        assigns(:city).should == "paris"
        assigns(:language).should == "ruby"
      end
    end
    
    context "No params for city and language" do
      it "defaults to SF and Javascript" do
        get :index
        assigns(:city).should == "san francisco"
        assigns(:language).should == "javascript"
      end
    end
    
    context "has results" do
      it "returns top users for this city and language ordered by city rank" do
        lr1 = FactoryGirl.create(:language_rank, :city => "paris", :language => "ruby", :city_rank => 1)
        lr3 = FactoryGirl.create(:language_rank, :city => "paris", :language => "ruby", :city_rank => 3)
        lr2 = FactoryGirl.create(:language_rank, :city => "paris", :language => "ruby", :city_rank => 2)
        
        get :index, :city => "Paris", :language => "Ruby"
        
        assigns(:language_ranks).should == [lr1, lr2, lr3]
      end
    end
    
    context "has no result" do
      it "returns empty" do
        get :index, :city => "Paris", :language => "Ruby"
        assigns(:language_ranks).should == []
      end
    end
  end
end