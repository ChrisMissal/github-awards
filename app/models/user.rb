class User < ActiveRecord::Base
  has_many :language_ranks
  validates :login, presence: true, uniqueness: true
end
