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

  # Legt die Reservierung an und "berührt" danach das Zeitfenster selbst in
  # derselben Transaktion, damit Rails' Optimistic Locking (lock_version)
  # greift: hat sich das Zeitfenster seit dem Laden bereits geändert (weil
  # jemand anderes zwischenzeitlich reserviert hat), wirft touch
  # ActiveRecord::StaleObjectError. Ein reines INSERT in reservierungen
  # allein würde lock_version auf zeitfenster nicht prüfen.
  def reserviert_von!(benutzer)
    transaction do
      reservierung = reservierungen.create!(benutzer: benutzer, erstellt_am: Time.current)
      touch
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
