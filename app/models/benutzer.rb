class Benutzer < ApplicationRecord
  enum :rolle, { mitglied: "mitglied", verantwortlicher: "verantwortlicher" }, default: :mitglied

  has_many :reservierungen, dependent: :restrict_with_error
  has_many :wartelisten, dependent: :destroy
  has_many :protokolle, foreign_key: :akteur_id, inverse_of: :akteur, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
