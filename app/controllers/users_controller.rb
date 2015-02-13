class UsersController < ApplicationController
  caches_action :index, :search, :show, :cache_path => Proc.new { |c| c.params }
  
  def index
    page = params[:page] || 0
    @city = params[:city].try(:downcase) || "san francisco"
    @language = params[:language].try(:downcase) || "javascript"
    @languages = Rails.cache.fetch("languages") { JSON.parse(File.read(Rails.root.join('app', 'assets', 'javascripts', 'languages.json'))) }
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
