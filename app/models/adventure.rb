# frozen_string_literal: true

class Adventure < ApplicationRecord
  enum status: {
    awaiting_start: 0,
    in_progress: 1,
    complete: 2,
    stopped: 3,
    abandoned: 4
  }

  has_many :adventure_food_trucks, dependent: :destroy
  has_many :food_trucks, through: :adventure_food_trucks

  validates :phone_number, presence: true, format: { with: /\A\d{10}\z/, message: 'must be 10 digits long' }
  validates :food_preference, presence: true
  validates :city, presence: true
  validates :zip_code, presence: true, format: { with: /\A\d{5}(-\d{4})?\z/, message: 'should be 5 or 9 digits long' }
  validates :number_of_trucks, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :adventure_day, presence: true
  validates :adventure_start_time, presence: true

  geocoded_by :zip_code
  after_validation :geocode

  before_update :clear_phone_number, if: :status_changed_to_final?
  after_create :organize_food_trucks, :schedule_initial_sms

  def next_truck
    adventure_food_trucks.find_by(order: current_truck_index)&.food_truck
  end

  def advance_to_next_truck!
    return unless next_truck

    update!(current_truck_index: current_truck_index + 1)
  end

  def on_last_truck?
    current_truck_index >= adventure_food_trucks.count - 1
  end

  def process_next_truck
    advance_to_next_truck! if current_truck_index.zero?

    return complete_message if complete?

    response = next_truck_message

    advance_to_next_truck!

    complete if on_last_truck?

    response
  end

  def complete_message
    {
      message: '🎉 Congratulations on completing your Food Truck Adventure! 🚚💨 You’ve tasted the best bites in town and lived to tell the tale. 🍔🌮🍕 Here’s to many more tasty trails! 🥂',
      status: :complete
    }
  end

  def next_truck_message
    {
      message: "🚚 Vroom, vroom! #{next_truck.applicant} is your next stop at #{next_truck.address}, #{next_truck.city}, #{next_truck.state}. Get ready for some tasty treats!",
      status: nil
    }
  end

  def stop
    update(status: :stopped)
  end

  def complete
    update(status: :complete)
  end

  def combined_start_time
    combined_datetime = DateTime.new(
      adventure_day.year,
      adventure_day.month,
      adventure_day.day,
      adventure_start_time.hour,
      adventure_start_time.min,
      adventure_start_time.sec
    ).in_time_zone('Pacific Time (US & Canada)')

    combined_datetime.strftime('%a, %d %b %Y %H:%M:%S %Z')
  end

  private

  def status_changed_to_final?
    saved_change_to_status? && %w[complete stopped abandoned].include?(status)
  end

  def clear_phone_number
    self.phone_number = nil
  end

  def schedule_initial_sms
    return unless status == 'awaiting_start'

    AdventureJob.set(wait_until: combined_start_time).perform_later(id)
  end

  def organize_food_trucks
    AdventureFoodTruckJob.perform_later(id)
  end
end
