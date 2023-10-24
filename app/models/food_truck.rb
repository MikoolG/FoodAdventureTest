# frozen_string_literal: true

class FoodTruck < ApplicationRecord
  has_many :adventure_food_trucks, dependent: :destroy
  has_many :adventures, through: :adventure_food_trucks

  validates :applicant, :address, :status, :latitude, :longitude, presence: true
  validates :applicant, :address, length: { maximum: 255 }

  scope :active, -> { where(active: true) }

  CATEGORIES = {
    'Breakfast Items' => %w[bacon eggs ham breakfast],
    'Hot Dogs' => %w[hot dogs sausage],
    'Beverages' => %w[beverages soda water juice drinks daiquiris coffee espresso tea matcha chai],
    'Pastries and Desserts' => %w[pastries croissants dessert sweets ice cream waffle cones flan cobbler donuts
                                  muffins],
    'Vegan' => %w[vegan],
    'Latin American Food' => %w[tacos burritos quesadillas tortas pupusas yucatan],
    'Asian Food' => %w[noodles filipino fusion sushi asian bao fried rice poke bowls],
    'Seafood' => %w[lobster crab ceviche tilapia fish],
    'Sandwiches, Melts, and Burgers' => %w[sandwiches melts burgers hamburger],
    'Fries, Chips, and Snacks' => %w[fries snacks chips onion rings kettlecorn],
    'Peruvian Food' => %w[peruvian],
    'Middle Eastern Food' => %w[halal gyro kebabs],
    'Bowls' => %w[salad bowls acai],
    'Cold Truck Items' => %w[cold truck],
    'Various Foods' => %w[food various many different chicken rotisserie mexican brazilian indian latin peruvian pizza
                          chili]
  }.freeze

  def expired?
    return true if expiration_date.nil?

    expiration_date < Date.today
  end
end
