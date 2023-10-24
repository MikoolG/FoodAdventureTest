# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SfImportWorker, type: :worker do
  let(:csv_url) { 'https://data.sfgov.org/api/views/rqzj-sfat/rows.csv?accessType=DOWNLOAD' }
  let(:csv_file_path) { Rails.root.join('spec', 'fixtures', 'test.csv') }

  before do
    allow(URI).to receive(:open).with(csv_url).and_return(File.open(csv_file_path))
  end

  describe '#perform' do
    it 'imports food trucks from the CSV file' do
      expect { SfImportWorker.new.perform }.to change { FoodTruck.count }.by(3)
    end

    it 'marks food trucks as inactive if they are not present in the CSV file' do
      create(:food_truck, applicant: 'Missing Applicant', active: true)
      SfImportWorker.new.perform
      expect(FoodTruck.find_by(applicant: 'Missing Applicant').active).to eq(false)
    end

    it 'updates existing food trucks if they are present in the CSV file' do
      create(:food_truck, applicant: 'Existing Applicant', address: '2301 MISSION ST', status: 'REQUESTED')
      SfImportWorker.new.perform
      expect(FoodTruck.find_by(applicant: 'Existing Applicant').status).to eq('APPROVED')
    end

    it 'checks for correct headers in the CSV file' do
      allow(URI).to receive(:open).with(csv_url).and_return(File.open(Rails.root.join('spec', 'fixtures',
                                                                                      'invalid_headers.csv')))
      expect { SfImportWorker.new.perform }.not_to(change { FoodTruck.count })
    end

    it 'handles an empty CSV file gracefully' do
      allow(URI).to receive(:open).with(csv_url).and_return(File.open(Rails.root.join('spec', 'fixtures', 'empty.csv')))
      expect { SfImportWorker.new.perform }.not_to(change { FoodTruck.count })
    end

    it 'raises an error for a malformed CSV file' do
      allow(URI).to receive(:open).with(csv_url).and_return(File.open(Rails.root.join('spec', 'fixtures',
                                                                                      'malformed.csv')))
      expect { SfImportWorker.new.perform }.to raise_error(CSV::MalformedCSVError)
    end

    it 'categorizes food items correctly' do
      SfImportWorker.new.perform
      expect(FoodTruck.find_by(applicant: 'Existing Applicant').categories).to include('Beverages')
    end
  end
end
