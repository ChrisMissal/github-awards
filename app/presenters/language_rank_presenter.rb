class LanguageRankPresenter
  def initialize(language_rank)
    @language_rank = language_rank
  end
  
  def city_rank
    "#{@language_rank.city_rank.gh_format} / #{@language_rank.country_user_count.gh_format}"
  end
  
  def country_rank
    "#{@language_rank.city_rank.gh_format} / #{@language_rank.country_user_count.gh_format}"
  end
  
  def world_rank
    "#{@language_rank.city_rank.gh_format} / #{@language_rank.country_user_count.gh_format}"
  end
end


class Fixnum
  include ActionView::Helpers::NumberHelper
  def gh_format
    number_with_delimiter(self, :delimiter => " ")
  end
end
