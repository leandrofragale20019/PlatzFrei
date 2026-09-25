# QA4 (Nachvollziehbarkeit): Sperrungen ohne betroffene Reservierung und das
# Aufheben von Sperrungen sollen ebenfalls protokolliert werden. Dafür kann ein
# Protokoll-Eintrag statt zu einer Reservierung direkt zu einem Zeitfenster
# gehören (genau eines von beiden, siehe Protokoll-Validierung).
class ErweiterProtokolleUmZeitfenster < ActiveRecord::Migration[8.1]
  def change
    change_column_null :protokolle, :reservierung_id, true
    # "zeitfenster" ist uncountable, daher Zieltabelle explizit.
    add_reference :protokolle, :zeitfenster, null: true, foreign_key: { to_table: :zeitfenster }
  end
end
