class Protokoll < ApplicationRecord
  enum :aktion, { erstellt: "erstellt", storniert: "storniert", geschlossen: "geschlossen" }

  belongs_to :reservierung
  belongs_to :akteur, class_name: "Benutzer", foreign_key: :akteur_id, inverse_of: :protokolle

  validates :zeitpunkt, presence: true
end
