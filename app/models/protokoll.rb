class Protokoll < ApplicationRecord
  enum :aktion, { erstellt: "erstellt", storniert: "storniert", geschlossen: "geschlossen", entsperrt: "entsperrt" }

  # Ein Eintrag gehört entweder zu einer Reservierung (erstellt, storniert,
  # geschlossen mit betroffener Reservierung) oder direkt zu einem Zeitfenster
  # (Sperrung ohne betroffene Reservierung, Aufheben einer Sperrung).
  belongs_to :reservierung, optional: true
  belongs_to :zeitfenster, optional: true
  belongs_to :akteur, class_name: "Benutzer", foreign_key: :akteur_id, inverse_of: :protokolle

  validates :zeitpunkt, presence: true
  validate :genau_ein_bezug

  def betroffenes_zeitfenster
    zeitfenster || reservierung&.zeitfenster
  end

  private

  def genau_ein_bezug
    return if reservierung.present? ^ zeitfenster.present?

    errors.add(:base, "muss sich auf genau eine Reservierung oder ein Zeitfenster beziehen")
  end
end
