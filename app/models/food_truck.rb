# frozen_string_literal: true

class FoodTruck < ApplicationRecord
  before_save :normalize_applicant_name
  validates :applicant, uniqueness: true
  validates :applicant, :facility_type, :address, :status, :latitude, :longitude, presence: true
  validates :applicant, :address, length: { maximum: 255 }

  scope :active, -> { where(active: true) }

  def expired?
    return true if expiration_date.nil?
    expiration_date < Date.today
  end

  def normalize_applicant_name
    self.applicant = applicant.titleize
  end
end
