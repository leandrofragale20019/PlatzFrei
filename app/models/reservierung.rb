class Reservierung < ApplicationRecord
  enum :status, { reserviert: "reserviert", storniert: "storniert" }, default: :reserviert

  belongs_to :benutzer
  belongs_to :zeitfenster
  has_many :protokolle, dependent: :restrict_with_error

  validates :erstellt_am, presence: true
end
