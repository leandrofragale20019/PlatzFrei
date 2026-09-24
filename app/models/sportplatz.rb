class Sportplatz < ApplicationRecord
  has_many :zeitfenster, dependent: :restrict_with_error

  validates :name, presence: true
  validates :sportart, presence: true

  # Sperrt alle Zeitfenster dieses Platzes im angegebenen Zeitraum und
  # storniert+protokolliert bestehende aktive Reservierungen darin, alles in
  # einer Transaktion (schlägt ein nicht abgefangener Schritt fehl, bleibt gar
  # nichts gesperrt).
  #
  # Nebenläufigkeit (QA5 – Stornierung vs. Sperrung): das Schliessen einer
  # Reservierung läuft über Reservierung#stornieren! (ein UPDATE), das durch
  # Optimistic Locking (lock_version auf reservierungen) geschützt ist.
  # Storniert ein Mitglied genau dieselbe Reservierung zeitgleich selbst, kann
  # unser update! hier auf einen veralteten Stand treffen und
  # ActiveRecord::StaleObjectError werfen. Für die Sperrung ist das kein
  # Fehler – die Reservierung ist ja bereits storniert –, deshalb wird dieser
  # Fall pro Reservierung in einem eigenen Savepoint (requires_new) abgefangen
  # und übersprungen, statt die gesamte Sperrung abzubrechen. Hat das Mitglied
  # schon vor dem Laden storniert, ist reservierungen.reserviert.first bereits
  # leer und es gibt schlicht nichts zu schliessen.
  #
  # (Die Doppelbuchung *neuer* Reservierungen ist ein anderes Problem und wird
  # allein vom partiellen Unique-Index auf reservierungen abgesichert, nicht
  # hier – siehe Zeitfenster#reserviert_von!.)
  #
  # Alternative wäre pessimistisches Locking gewesen (SQLite BEGIN IMMEDIATE):
  # das würde den Konflikt durch Blockieren von vornherein vermeiden, dafür
  # aber die ganze DB für die Dauer der Sperrung exklusiv sperren und den viel
  # häufigeren Reservierungs-Hotpath ausbremsen – die falsche Priorisierung
  # für diese App.
  def sperren!(von:, bis:, akteur:)
    transaction do
      zeitfenster.where(start: von..bis).each do |zf|
        zf.update!(gesperrt: true)
        aktive = zf.reservierungen.reserviert.first
        next unless aktive

        begin
          transaction(requires_new: true) do
            aktive.stornieren!(akteur: akteur, aktion: :geschlossen)
          end
        rescue ActiveRecord::StaleObjectError
          # Mitglied hat dieselbe Reservierung zeitgleich selbst storniert –
          # sie ist bereits weg, also überspringen (Sperrung nicht abbrechen).
          Rails.logger.info("Sperrung #{id}: Reservierung #{aktive.id} wurde zeitgleich storniert – übersprungen.")
        end
      end
    end
  end
end
