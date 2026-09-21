class Sportplatz < ApplicationRecord
  has_many :zeitfenster, dependent: :restrict_with_error

  validates :name, presence: true
  validates :sportart, presence: true
end
