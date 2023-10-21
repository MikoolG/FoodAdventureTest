# frozen_string_literal: true

require 'open-uri'
require 'csv'

class SfImportWorker
  include Sidekiq::Worker

  def perform
    csv_url = 'https://data.sfgov.org/api/views/rqzj-sfat/rows.csv?accessType=DOWNLOAD'
    csv_text = URI.open(csv_url).read
    csv = CSV.parse(csv_text, headers: true)

    # Verify headers
    expected_headers = ['locationid', 'Applicant', 'FacilityType', 'cnn', 'LocationDescription', 'Address', 'blocklot',
                        'block', 'lot', 'permit', 'Status', 'FoodItems', 'X', 'Y', 'Latitude', 'Longitude', 'Schedule', 'dayshours', 'NOISent', 'Approved', 'Received', 'PriorPermit', 'ExpirationDate', 'Location', 'Fire Prevention Districts', 'Police Districts', 'Supervisor Districts', 'Zip Codes', 'Neighborhoods (old)']
    return unless csv.headers == expected_headers

    # Process CSV rows
    applicant_names_in_csv = []
    csv.each do |row|
      applicant_names_in_csv << row['Applicant']

      expiration_date_str = row['expiration_date']
      expiration_date = unless expiration_date_str.blank?
                          DateTime.strptime(expiration_date_str, '%m/%d/%Y %I:%M:%S %p').to_date
                        end

      food_truck = FoodTruck.find_or_initialize_by(applicant: row['Applicant'])
      food_truck.update(
        facility_type: row['FacilityType'],
        location_description: row['LocationDescription'],
        address: row['Address'],
        status: row['Status'],
        food_items: row['FoodItems'],
        latitude: row['Latitude'],
        longitude: row['Longitude'],
        schedule: row['Schedule'],
        days_hours: row['dayshours'],
        expiration_date:,
        active: true
      )
    end

    # Mark records as inactive if they are not present in the CSV
    FoodTruck.where.not(applicant: applicant_names_in_csv).update_all(active: false)
  end
end
