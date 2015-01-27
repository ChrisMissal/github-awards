class CityWorker
  include Sidekiq::Worker

  def perform(attributes)
    City.create(:country => attributes[0],
        :city => attributes[1],
        :accented_city => attributes[2])
  end
end