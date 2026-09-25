class Sportplatz < ApplicationRecord
  has_many :zeitfenster, dependent: :restrict_with_error

  validates :name, presence: true
  validates :sportart, presence: true

  # Sperrt alle (noch nicht gesperrten) Zeitfenster dieses Platzes im
  # angegebenen Zeitraum und storniert+protokolliert bestehende aktive
  # Reservierungen darin, alles in einer Transaktion (schlägt ein nicht
  # abgefangener Schritt fehl, bleibt gar nichts gesperrt).
  #
  # Protokoll (QA4): jedes gesperrte Zeitfenster erzeugt genau einen
  # "geschlossen"-Eintrag – an der stornierten Reservierung, falls eine
  # betroffen war, sonst direkt am Zeitfenster. Bereits gesperrte Zeitfenster
  # werden übersprungen, damit ein erneutes Sperren keine Doppeleinträge
  # erzeugt (sie können ohnehin keine aktive Reservierung mehr haben).
  #
  # Nebenläufigkeit (QA5 – Stornierung vs. Sperrung): das Schliessen einer
  # Reservierung läuft über Reservierung#stornieren! (ein UPDATE), das durch
  # Optimistic Locking (lock_version auf reservierungen) geschützt ist.
  # Storniert ein Mitglied genau dieselbe Reservierung zeitgleich selbst, kann
  # unser update! hier auf einen veralteten Stand treffen und
  # ActiveRecord::StaleObjectError werfen. Für die Sperrung ist das kein
  # Fehler – die Reservierung ist ja bereits storniert –, deshalb wird dieser
  # Fall pro Reservierung in einem eigenen Savepoint (requires_new) abgefangen
  # und übersprungen, statt die gesamte Sperrung abzubrechen (die Sperrung des
  # Zeitfensters wird dann am Zeitfenster protokolliert). Hat das Mitglied
  # schon vor dem Laden storniert, ist reservierungen.reserviert.first bereits
  # leer und es gibt schlicht keine Reservierung zu schliessen.
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
      zeitfenster.where(gesperrt: false, start: von..bis).each do |zf|
        zf.update!(gesperrt: true)
        aktive = zf.reservierungen.reserviert.first
        next if aktive && reservierung_schliessen(aktive, akteur)

        zf.protokolle.create!(akteur: akteur, aktion: :geschlossen, zeitpunkt: Time.current)
      end
    end
  end

  # Hebt die Sperrung aller Zeitfenster dieses Platzes im Zeitraum wieder auf
  # und protokolliert das pro Zeitfenster (QA4), atomar in einer Transaktion.
  # Durch die Sperrung stornierte Reservierungen bleiben storniert (die
  # Mitglieder wurden bereits informiert); die Slots werden einfach wieder
  # frei, und Wartende sehen sie als "Jetzt frei!".
  def entsperren!(von:, bis:, akteur:)
    transaction do
      zeitfenster.where(gesperrt: true, start: von..bis).find_each do |zf|
        zf.update!(gesperrt: false)
        zf.protokolle.create!(akteur: akteur, aktion: :entsperrt, zeitpunkt: Time.current)
      end
    end
  end

  private

  # Storniert die Reservierung im Rahmen einer Sperrung in einem eigenen
  # Savepoint. Liefert false, wenn das Mitglied sie zeitgleich selbst storniert
  # hat (StaleObjectError) – dann wird übersprungen statt abgebrochen.
  def reservierung_schliessen(reservierung, akteur)
    transaction(requires_new: true) do
      reservierung.stornieren!(akteur: akteur, aktion: :geschlossen)
    end
    true
  rescue ActiveRecord::StaleObjectError
    Rails.logger.info("Sperrung #{id}: Reservierung #{reservierung.id} wurde zeitgleich storniert – übersprungen.")
    false
  end
end
