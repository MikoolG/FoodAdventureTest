class FoodTruck < ApplicationRecord
    validates :applicant, :facility_type, :address, :status, presence: true
    validates :latitude, :longitude, numericality: true, allow_blank: true
end
