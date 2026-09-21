class Warteliste < ApplicationRecord
  belongs_to :zeitfenster
  belongs_to :benutzer

  validates :benutzer_id, uniqueness: { scope: :zeitfenster_id }
end
