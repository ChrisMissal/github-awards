class UsersController < ApplicationController
  def index
    puts "flash = #{flash[:alert]}"
    page = params[:page] || 0
    @city = params[:city].try(:downcase) || "paris"
    @language = params[:language].try(:downcase) || "ruby"
    @languages = LanguageRank.select(:language).order("language ASC").distinct.map{|l| l.language.capitalize}
    @language_ranks = LanguageRank.includes(:user).where(:city => @city, :language => @language).order("city_rank ASC").page(page).per(25)
  end
  
  def search
    @user = User.where(:login => params[:login]).first
    if @user
      @language_ranks = @user.language_ranks
      render action: 'show'
    else
      redirect_to users_path, :alert => "User #{params[:login]} not found"
    end
  end

  def show
    @user = User.where(:login => params[:id]).first
    @language_ranks = @user.language_ranks
  end
end
