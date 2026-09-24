class Reservierung < ApplicationRecord
  enum :status, { reserviert: "reserviert", storniert: "storniert" }, default: :reserviert

  belongs_to :benutzer
  belongs_to :zeitfenster
  has_many :protokolle, dependent: :restrict_with_error

  validates :erstellt_am, presence: true

  # Storniert die Reservierung und protokolliert das atomar.
  #
  # Optimistic Locking (lock_version auf reservierungen): stornieren! ist ein
  # UPDATE auf eine *bestehende* Reservierung. Wird dieselbe Reservierung
  # nebenläufig ein zweites Mal verändert – der reale Konfliktfall der App:
  # ein Mitglied storniert selbst, während der/die Platzverantwortliche den
  # Platz sperrt und dabei genau diese Reservierung schliesst –, erkennt Rails
  # den veralteten lock_version-Stand und wirft ActiveRecord::StaleObjectError,
  # statt die Reservierung ein zweites Mal (mit evtl. veralteten Daten) zu
  # überschreiben. Wer zuerst schreibt, gewinnt; der spätere Zugriff wird
  # abgewiesen und an der aufrufenden Stelle behandelt.
  def stornieren!(akteur:, aktion: :storniert)
    transaction do
      update!(status: :storniert)
      protokolle.create!(akteur: akteur, aktion: aktion, zeitpunkt: Time.current)
    end
  end
end
