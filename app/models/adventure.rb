# frozen_string_literal: true

class Adventure < ApplicationRecord
    enum status: {
        in_progress: 0,
        complete: 1,
        stopped: 2,
        abandoned: 3
      }
      
    validates :phone_number, presence: true, format: { with: /\A\d{10}\z/, message: "must be 10 digits long" }
    validates :food_preference, presence: true
    validates :city, presence: true
    validates :state, presence: true, length: { is: 2 }
    validates :zip_code, presence: true, format: { with: /\A\d{5}(-\d{4})?\z/, message: "should be 5 or 9 digits long" }
    validates :number_of_trucks, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :adventure_day, presence: true
    validates :adventure_start_time, presence: true
  end
  