class UsersController < ApplicationController
  caches_action :index, :search, :show, :cache_path => Proc.new { |c| c.params }
  
  def index
    page = params[:page] || 0
    @city = params[:city].try(:downcase) || "san francisco"
    @language = params[:language].try(:downcase) || "javascript"
    @language_ranks = LanguageRank.includes(:user).where(:city => @city, :language => @language).order("city_rank ASC").page(page).per(25)
  end
  
  def search
    show_user(params[:login])
    rescue ActiveRecord::RecordNotFound => e
      redirect_to users_path, :alert => "User #{params[:login]} not found"
  end

  def show
    show_user(params[:id])
  end
  
  private 
  
  def show_user(login)
    @user = User.where(:login => login).first || not_found
    @language_ranks = @user.language_ranks
    render action: 'show'
  end
end
