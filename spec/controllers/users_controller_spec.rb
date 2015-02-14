# encoding: utf-8
require 'rails_helper'

describe UsersController do
  describe "GET show" do
    context "user exists" do
      before(:each) do
        @user = FactoryGirl.create(:user, :login => "vdaubry")
        @language_ranks = FactoryGirl.create_list(:language_rank, 2, :user => @user)
      end
      
      it "sets user" do
        get :show, :id => "vdaubry"
        assigns(:user).should == @user
      end
      
      it "sets language_ranks" do
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
end