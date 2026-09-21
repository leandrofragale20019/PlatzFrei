class Sportplatz < ApplicationRecord
  has_many :zeitfenster, dependent: :restrict_with_error

  validates :name, presence: true
  validates :sportart, presence: true

  # Sperrt alle Zeitfenster dieses Platzes im angegebenen Zeitraum und
  # storniert+protokolliert bestehende aktive Reservierungen darin, alles in
  # einer Transaktion (schlägt irgendein Schritt fehl, bleibt gar nichts
  # gesperrt).
  #
  # Nebenläufigkeit (QA5): jedes betroffene Zeitfenster wird per update!
  # einzeln gesperrt (nicht per Bulk-update_all, das Optimistic Locking
  # umgehen würde). Da Zeitfenster#reserviert_von! (Schritt 6) dasselbe
  # Zeitfenster-Row per touch anfasst, erkennt Rails automatisch einen
  # Konflikt, falls jemand während der Sperrung genau dieses Zeitfenster
  # reserviert: entweder committet die fremde Reservierung zuerst (dann
  # findet reservierungen.reserviert.first sie hier und storniert sie mit),
  # oder unser update! committet zuerst (dann scheitert die fremde
  # Reservierung an ActiveRecord::StaleObjectError). Eine "Geister-
  # Reservierung" ist damit ausgeschlossen.
  #
  # Alternative wäre pessimistisches Locking gewesen (SQLite BEGIN
  # IMMEDIATE): das würde den seltenen Konflikt von vornherein durch
  # Blockieren vermeiden, statt die gesamte Sperrung abzubrechen und dem
  # Manager einen erneuten Versuch abzuverlangen. Dagegen spricht, dass
  # BEGIN IMMEDIATE die komplette Datenbank für die Dauer der Sperrung
  # exklusiv sperrt und damit den viel häufigeren Reservierungs-Hotpath
  # ausbremst, nur um den seltenen, Manager-initiierten Sperrungsfall
  # etwas komfortabler zu machen — die falsche Priorisierung für diese App.
  def sperren!(von:, bis:, akteur:)
    transaction do
      zeitfenster.where(start: von..bis).each do |zf|
        zf.update!(gesperrt: true)
        zf.reservierungen.reserviert.first&.stornieren!(akteur: akteur, aktion: :geschlossen)
      end
    end
  end
end
