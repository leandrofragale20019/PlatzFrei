class Zeitfenster < ApplicationRecord
  belongs_to :sportplatz
  has_many :reservierungen, dependent: :restrict_with_error
  has_many :wartelisten, dependent: :destroy

  validates :start, presence: true
  validates :ende, presence: true
  validate :ende_nach_start
  validate :keine_ueberlappung

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
