# frozen_string_literal: true

class Adventure < ApplicationRecord
  enum status: {
    awaiting_start: 0,
    in_progress: 1,
    complete: 2,
    stopped: 3,
    abandoned: 4
  }

  validates :phone_number, presence: true, format: { with: /\A\d{10}\z/, message: 'must be 10 digits long' }
  validates :food_preference, presence: true
  validates :city, presence: true
  validates :state, presence: true, length: { is: 2 }
  validates :zip_code, presence: true, format: { with: /\A\d{5}(-\d{4})?\z/, message: 'should be 5 or 9 digits long' }
  validates :number_of_trucks, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :adventure_day, presence: true
  validates :adventure_start_time, presence: true

  before_update :clear_phone_number, if: :status_changed_to_final?
  after_create :schedule_initial_sms

  private

  def status_changed_to_final?
    saved_change_to_status? && %w[complete stopped abandoned].include?(status)
  end

  def clear_phone_number
    self.phone_number = nil
  end

  def schedule_initial_sms
    return unless status == 'awaiting_start'

    AdventureJob.set(wait_until: adventure_start_time).perform_later(id)
  end
end
