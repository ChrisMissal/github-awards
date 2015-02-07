class LanguageRank < ActiveRecord::Base
  belongs_to :user
  validates :language, :score, :rank, :repository_count, :stars_count, presence: true
  validates :language, uniqueness: {scope: [:user_id, :city, :country]}
end
