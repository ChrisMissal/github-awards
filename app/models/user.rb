class User < ActiveRecord::Base
  validates :login, presence: true, uniqueness: true
end
