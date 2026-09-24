class Zeitfenster < ApplicationRecord
  belongs_to :sportplatz
  has_many :reservierungen, dependent: :restrict_with_error
  has_many :wartelisten, dependent: :destroy

  validates :start, presence: true
  validates :ende, presence: true
  validate :ende_nach_start
  validate :keine_ueberlappung

  scope :frei, -> { where(gesperrt: false).where.not(id: Reservierung.reserviert.select(:zeitfenster_id)) }

  def aktive_reservierung
    reservierungen.detect(&:reserviert?)
  end

  # Legt eine neue Reservierung für dieses Zeitfenster an (atomar mit dem
  # zugehörigen Protokoll-Eintrag).
  #
  # Schutz gegen Doppelbuchung: ausschliesslich der partielle Unique-Index auf
  # reservierungen (zeitfenster_id, WHERE status = 'reserviert'). Reservieren
  # zwei Mitglieder denselben Slot nahezu gleichzeitig, gelingt genau ein
  # INSERT; der zweite scheitert mit ActiveRecord::RecordNotUnique.
  #
  # lock_version (Optimistic Locking) greift hier bewusst NICHT: es schützt nur
  # UPDATEs an einer bereits bestehenden Zeile, nicht das INSERT einer neuen
  # Reservierung. Der eigentliche Optimistic-Locking-Fall der App liegt auf der
  # bestehenden Reservierung (Stornierung vs. Sperrung), siehe
  # Reservierung#stornieren! und Sportplatz#sperren!.
  def reserviert_von!(benutzer)
    transaction do
      reservierung = reservierungen.create!(benutzer: benutzer, erstellt_am: Time.current)
      reservierung.protokolle.create!(akteur: benutzer, aktion: :erstellt, zeitpunkt: Time.current)
      reservierung
    end
  end

  private

  def ende_nach_start
    return if start.blank? || ende.blank?

    errors.add(:ende, "muss nach dem Start liegen") if ende <= start
  end

  def keine_ueberlappung
    return if start.blank? || ende.blank? || sportplatz_id.blank?

    overlappend = Zeitfenster
      .where(sportplatz_id: sportplatz_id)
      .where.not(id: id)
      .where("start < ? AND ende > ?", ende, start)

    errors.add(:base, "überlappt mit einem bestehenden Zeitfenster für diesen Sportplatz") if overlappend.exists?
  end
end
