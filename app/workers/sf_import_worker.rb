# frozen_string_literal: true

require 'open-uri'
require 'csv'

class SfImportWorker
  include Sidekiq::Worker

  CSV_URL = 'https://data.sfgov.org/api/views/rqzj-sfat/rows.csv?accessType=DOWNLOAD'
  EXPECTED_HEADERS = ['locationid', 'Applicant', 'FacilityType', 'cnn', 'LocationDescription', 'Address', 'blocklot',
                      'block', 'lot', 'permit', 'Status', 'FoodItems', 'X', 'Y', 'Latitude', 'Longitude', 'Schedule', 'dayshours', 'NOISent', 'Approved', 'Received', 'PriorPermit', 'ExpirationDate', 'Location', 'Fire Prevention Districts', 'Police Districts', 'Supervisor Districts', 'Zip Codes', 'Neighborhoods (old)'].freeze

  def perform
    return unless valid_headers?

    applicant_names_in_csv = []

    parsed_csv.each do |row|
      applicant_names_in_csv << row['Applicant']
      update_or_create_food_truck(row)
    end

    mark_missing_records_as_inactive(applicant_names_in_csv)
  end

  private

  def parsed_csv
    @parsed_csv ||= CSV.parse(csv_text, headers: true)
  end

  def csv_text
    URI.open(CSV_URL).read
  rescue StandardError => e
    Rails.logger.error("Failed to fetch CSV from #{CSV_URL}: #{e.message}")
    ''
  end

  def valid_headers?
    parsed_csv.headers == EXPECTED_HEADERS
  end

  def update_or_create_food_truck(row)
    expiration_date = parse_expiration_date(row['ExpirationDate'])
    categories = categorize_food(row['FoodItems'])

    food_truck = FoodTruck.find_or_initialize_by(applicant: row['Applicant'])
    food_truck.assign_attributes(
      facility_type: row['FacilityType'],
      location_description: row['LocationDescription'],
      address: row['Address'],
      status: row['Status'],
      food_items: row['FoodItems'],
      categories: categories,
      latitude: row['Latitude'],
      longitude: row['Longitude'],
      schedule: row['Schedule'],
      days_hours: row['dayshours'],
      expiration_date:,
      active: true
    )
    food_truck.save!
  end

  def categorize_food(food_items)
    return [] unless food_items

    categories = []

    FoodTruck::CATEGORIES.each do |category, keywords|
      categories << category if keywords.any? { |keyword| food_items.downcase.include?(keyword.downcase) }
    end

    categories
  end

  def parse_expiration_date(expiration_date_str)
    return if expiration_date_str.blank?

    DateTime.strptime(expiration_date_str, '%m/%d/%Y %I:%M:%S %p').to_date
  end

  def mark_missing_records_as_inactive(applicant_names)
    FoodTruck.where.not(applicant: applicant_names).update_all(active: false)
  end
end
